CREATE OR REPLACE TABLE rthompson1.product_master (
    product_number VARCHAR(20) PRIMARY KEY,
    description VARCHAR(100),
    cost DECIMAL(10, 2),
    unit_of_measure VARCHAR(10),
    category VARCHAR(50)
) 
On Replace Delete Rows;

INSERT INTO rthompson1.product_master (product_number, description, cost, unit_of_measure, category) VALUES
('P0001', 'Wireless Mouse', 19.99, 'EACH', 'Electronics'),
('P0002', 'Bluetooth Keyboard', 29.95, 'EACH', 'Electronics'),
('P0003', 'USB-C Charger', 14.50, 'EACH', 'Electronics'),
('P0004', 'Laptop Backpack', 45.00, 'EACH', 'Accessories'),
('P0005', '16GB USB Drive', 9.99, 'EACH', 'Electronics'),
('P0006', 'Coffee Mug', 5.25, 'EACH', 'Kitchen'),
('P0007', 'Notebook - Lined', 3.15, 'EACH', 'Stationery'),
('P0008', 'Ballpoint Pens (Pack of 10)', 2.99, 'PACK', 'Stationery'),
('P0009', 'Desk Lamp', 18.75, 'EACH', 'Office'),
('P0010', 'Wireless Headphones', 59.95, 'EACH', 'Electronics'),
('P0011', 'Stapler', 6.49, 'EACH', 'Office'),
('P0012', 'Pack of Sticky Notes', 1.99, 'PACK', 'Stationery'),
('P0013', 'AA Batteries (4 Pack)', 4.25, 'PACK', 'Electronics'),
('P0014', 'Toaster Oven', 39.95, 'EACH', 'Kitchen'),
('P0015', 'Water Bottle 1L', 7.89, 'EACH', 'Kitchen'),
('P0016', 'LED Light Bulbs (6 Pack)', 12.49, 'PACK', 'Home Improvement'),
('P0017', 'Phone Charger Cable', 8.95, 'EACH', 'Electronics'),
('P0018', 'Notebook Cooling Pad', 21.99, 'EACH', 'Electronics'),
('P0019', 'Mechanical Pencil Set (2 Pack)', 4.75, 'PACK', 'Stationery'),
('P0020', 'Electric Kettle', 24.50, 'EACH', 'Kitchen');
