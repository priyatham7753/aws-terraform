const {
  GetCommand,
  PutCommand,
  UpdateCommand,
  ScanCommand,
  QueryCommand
} = require('@aws-sdk/lib-dynamodb');
const { docClient, PRODUCTS_TABLE } = require('../db/dynamodb');
const { v4: uuidv4 } = require('uuid');

const VALID_CATEGORIES = [
  'Electronics', 'Clothing', 'Books', 'Food',
  'Furniture', 'Sports', 'Toys', 'Beauty', 'Other'
];

/**
 * List active products with optional filters.
 * Uses a Scan (DynamoDB Local/small dataset) with FilterExpression.
 * For production scale, use a GSI on isActive+category.
 */
const listProducts = async ({ category, minPrice, maxPrice, search, page = 1, limit = 20 }) => {
  const filterParts = ['isActive = :active'];
  const exprValues = { ':active': true };

  if (category) {
    filterParts.push('category = :cat');
    exprValues[':cat'] = category;
  }
  if (minPrice !== undefined) {
    filterParts.push('price >= :minp');
    exprValues[':minp'] = parseFloat(minPrice);
  }
  if (maxPrice !== undefined) {
    filterParts.push('price <= :maxp');
    exprValues[':maxp'] = parseFloat(maxPrice);
  }

  const params = {
    TableName: PRODUCTS_TABLE,
    FilterExpression: filterParts.join(' AND '),
    ExpressionAttributeValues: exprValues
  };

  const result = await docClient.send(new ScanCommand(params));
  let items = result.Items || [];

  // In-memory search (DynamoDB doesn't have full-text search natively)
  if (search) {
    const lower = search.toLowerCase();
    items = items.filter(
      (p) =>
        p.name.toLowerCase().includes(lower) ||
        p.description.toLowerCase().includes(lower)
    );
  }

  // Sort by createdAt descending
  items.sort((a, b) => (b.createdAt > a.createdAt ? 1 : -1));

  const total = items.length;
  const startIdx = (parseInt(page) - 1) * parseInt(limit);
  const paginated = items.slice(startIdx, startIdx + parseInt(limit));

  return {
    products: paginated,
    pagination: {
      total,
      page: parseInt(page),
      limit: parseInt(limit),
      pages: Math.ceil(total / parseInt(limit))
    }
  };
};

/**
 * Get a single product by productId.
 */
const getProductById = async (productId) => {
  const result = await docClient.send(
    new GetCommand({
      TableName: PRODUCTS_TABLE,
      Key: { productId }
    })
  );
  return result.Item || null;
};

/**
 * Create a new product item.
 */
const createProduct = async ({ name, description, price, category, stock, imageUrl }) => {
  const now = new Date().toISOString();
  const productId = uuidv4();

  const item = {
    productId,
    name: name.trim(),
    description: description.trim(),
    price: parseFloat(price),
    category,
    stock: parseInt(stock),
    imageUrl: imageUrl || 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
    isActive: true,
    createdAt: now,
    updatedAt: now
  };

  await docClient.send(
    new PutCommand({
      TableName: PRODUCTS_TABLE,
      Item: item,
      ConditionExpression: 'attribute_not_exists(productId)'
    })
  );

  return item;
};

/**
 * Update an existing product. Returns updated item.
 */
const updateProduct = async (productId, updates) => {
  const existing = await getProductById(productId);
  if (!existing) return null;

  const now = new Date().toISOString();
  const updatable = { ...existing, ...updates, productId, updatedAt: now };

  await docClient.send(
    new PutCommand({ TableName: PRODUCTS_TABLE, Item: updatable })
  );

  return updatable;
};

/**
 * Soft-delete a product by setting isActive=false.
 */
const softDeleteProduct = async (productId) => {
  const existing = await getProductById(productId);
  if (!existing) return null;

  const updated = { ...existing, isActive: false, updatedAt: new Date().toISOString() };
  await docClient.send(new PutCommand({ TableName: PRODUCTS_TABLE, Item: updated }));
  return updated;
};

/**
 * Count all active products (used for seeding check).
 */
const countActiveProducts = async () => {
  const result = await docClient.send(
    new ScanCommand({
      TableName: PRODUCTS_TABLE,
      FilterExpression: 'isActive = :a',
      ExpressionAttributeValues: { ':a': true },
      Select: 'COUNT'
    })
  );
  return result.Count || 0;
};

/**
 * Seed initial products if table is empty.
 */
const seedProducts = async () => {
  const sampleProducts = [
    { name: 'Wireless Noise-Cancelling Headphones', description: 'Premium sound quality with 30-hour battery life and foldable design.', price: 299.99, category: 'Electronics', stock: 50, imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400' },
    { name: 'Mechanical Gaming Keyboard', description: 'RGB backlit mechanical keyboard with tactile switches and N-key rollover.', price: 149.99, category: 'Electronics', stock: 75, imageUrl: 'https://images.unsplash.com/photo-1541140532154-b024d705b90a?w=400' },
    { name: 'Ergonomic Office Chair', description: 'Lumbar support, adjustable armrests, and breathable mesh back for all-day comfort.', price: 459.99, category: 'Furniture', stock: 20, imageUrl: 'https://images.unsplash.com/photo-1541558869434-2840d308329a?w=400' },
    { name: 'Stainless Steel Water Bottle', description: 'Keeps drinks cold 24 hours or hot 12 hours, BPA-free with leak-proof lid.', price: 34.99, category: 'Sports', stock: 200, imageUrl: 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400' },
    { name: 'Smart Watch Pro', description: 'Health monitoring, GPS, sleep tracking, and 7-day battery life.', price: 399.99, category: 'Electronics', stock: 35, imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400' },
    { name: 'Running Shoes Ultra Boost', description: 'Lightweight, responsive cushioning for everyday training and long runs.', price: 129.99, category: 'Sports', stock: 100, imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400' },
    { name: 'Portable Bluetooth Speaker', description: '360° surround sound, waterproof IPX7, 20-hour playtime.', price: 79.99, category: 'Electronics', stock: 60, imageUrl: 'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=400' },
    { name: 'Organic Coffee Blend', description: 'Single-origin, fair-trade Ethiopian coffee beans, medium roast.', price: 24.99, category: 'Food', stock: 150, imageUrl: 'https://images.unsplash.com/photo-1447933601403-0c6688de566e?w=400' }
  ];

  for (const p of sampleProducts) {
    await createProduct(p);
  }
  console.log(`[PRODUCT-SERVICE] Seeded ${sampleProducts.length} sample products`);
};

module.exports = {
  listProducts,
  getProductById,
  createProduct,
  updateProduct,
  softDeleteProduct,
  countActiveProducts,
  seedProducts,
  VALID_CATEGORIES
};
