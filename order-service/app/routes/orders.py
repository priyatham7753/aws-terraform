import logging
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status

from app.dependencies import get_current_user, get_product_details
from app.models import (
    CreateOrderRequest,
    OrderResponse,
    OrderStatus,
    UpdateOrderStatusRequest,
)
from app.repositories import order_repository
from app.services import sqs_service, sns_service

router = APIRouter()
logger = logging.getLogger(__name__)


@router.post("/", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
async def create_order(
    order_data: CreateOrderRequest,
    current_user: dict = Depends(get_current_user),
):
    """Create a new order after validating products with Product Service."""
    order_items = []
    total_amount = 0.0

    for item in order_data.items:
        product = await get_product_details(item.product_id)

        if product.get("stock", 0) < item.quantity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Insufficient stock for product '{product['name']}'"
            )

        subtotal = round(product["price"] * item.quantity, 2)
        total_amount += subtotal

        order_items.append({
            "product_id": item.product_id,
            "product_name": product["name"],
            "product_price": product["price"],
            "quantity": item.quantity,
            "subtotal": subtotal,
        })

    order = order_repository.create_order(
        user_id=current_user["userId"],
        user_email=current_user["email"],
        items=order_items,
        total_amount=total_amount,
        shipping_address=order_data.shipping_address,
    )

    logger.info(f"Order created: {order['order_id']} for user {current_user['email']}")

    # Publish to SQS and SNS (non-blocking)
    sqs_service.send_order_event(order)
    sns_service.notify_order_created(order)

    return order


@router.get("/", response_model=List[OrderResponse])
async def get_my_orders(
    status_filter: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """Get all orders for the current authenticated user."""
    orders = order_repository.get_orders_by_user(
        user_id=current_user["userId"],
        status_filter=status_filter,
    )
    return orders


@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get a specific order by ID (owner or admin only)."""
    order = order_repository.get_order_by_id(order_id)

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )

    if order["user_id"] != current_user["userId"] and current_user.get("role") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )

    return order


@router.patch("/{order_id}/status", response_model=OrderResponse)
async def update_order_status(
    order_id: str,
    status_update: UpdateOrderStatusRequest,
    current_user: dict = Depends(get_current_user),
):
    """Update order status (owner can cancel; admin can set any status)."""
    order = order_repository.get_order_by_id(order_id)

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )

    if order["user_id"] != current_user["userId"] and current_user.get("role") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )

    if current_user.get("role") != "admin" and status_update.status != OrderStatus.CANCELLED:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Users can only cancel their own orders"
        )

    updated = order_repository.update_order_status(order_id, status_update.status)
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found or could not be updated"
        )

    logger.info(f"Order {order_id} status updated to {status_update.status}")

    # Notify via SNS
    sns_service.notify_order_status_changed(
        order_id=order_id,
        new_status=status_update.status,
        user_email=order.get("user_email", ""),
    )

    return updated
