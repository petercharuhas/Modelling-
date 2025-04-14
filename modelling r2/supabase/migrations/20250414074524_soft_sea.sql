/*
  # Craigslist Database Schema

  1. New Tables
    - regions
      - id (uuid, primary key)
      - name (text)
      - created_at (timestamp)
    
    - users
      - id (uuid, primary key)
      - email (text)
      - preferred_region_id (uuid, foreign key)
      - created_at (timestamp)
    
    - categories
      - id (uuid, primary key)
      - name (text)
      - description (text)
      - created_at (timestamp)
    
    - posts
      - id (uuid, primary key)
      - title (text)
      - text (text)
      - user_id (uuid, foreign key)
      - region_id (uuid, foreign key)
      - category_id (uuid, foreign key)
      - location (text)
      - created_at (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create regions table
CREATE TABLE IF NOT EXISTS regions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  created_at timestamptz DEFAULT now()
);

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL UNIQUE,
  preferred_region_id uuid REFERENCES regions(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text,
  created_at timestamptz DEFAULT now()
);

-- Create posts table
CREATE TABLE IF NOT EXISTS posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  text text NOT NULL,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  region_id uuid REFERENCES regions(id) ON DELETE CASCADE NOT NULL,
  category_id uuid REFERENCES categories(id) ON DELETE CASCADE NOT NULL,
  location text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE regions ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow authenticated users to read regions"
  ON regions
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to read categories"
  ON categories
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to read posts"
  ON posts
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can read their own data"
  ON users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Insert sample data
INSERT INTO regions (name) VALUES
  ('San Francisco'),
  ('Atlanta'),
  ('Seattle'),
  ('New York'),
  ('Los Angeles');

INSERT INTO categories (name, description) VALUES
  ('Housing', 'Apartments, houses, and rooms for rent'),
  ('Jobs', 'Employment opportunities'),
  ('For Sale', 'Items for sale'),
  ('Services', 'Professional and personal services'),
  ('Community', 'Local events and activities');

-- Create a test user
INSERT INTO users (email, preferred_region_id)
SELECT 
  'test@example.com',
  id
FROM regions
WHERE name = 'San Francisco';

-- Create some sample posts
INSERT INTO posts (title, text, user_id, region_id, category_id, location)
SELECT 
  'Beautiful Apartment for Rent',
  'Spacious 2BR apartment in downtown area. Available immediately.',
  u.id,
  r.id,
  c.id,
  'Downtown San Francisco'
FROM users u, regions r, categories c
WHERE r.name = 'San Francisco' AND c.name = 'Housing'
LIMIT 1;