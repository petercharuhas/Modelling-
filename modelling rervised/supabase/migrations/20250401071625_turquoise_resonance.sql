/*
  # Medical Center Database Schema

  1. New Tables
    - `doctors`
      - `id` (uuid, primary key)
      - `first_name` (text)
      - `last_name` (text)
      - `specialty` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
    - `patients`
      - `id` (uuid, primary key)
      - `first_name` (text)
      - `last_name` (text)
      - `date_of_birth` (date)
      - `email` (text)
      - `phone` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
    - `visits`
      - `id` (uuid, primary key)
      - `patient_id` (uuid, foreign key)
      - `doctor_id` (uuid, foreign key)
      - `visit_date` (timestamp)
      - `notes` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
    - `diseases`
      - `id` (uuid, primary key)
      - `name` (text)
      - `description` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
    - `visit_diagnoses`
      - `id` (uuid, primary key)
      - `visit_id` (uuid, foreign key)
      - `disease_id` (uuid, foreign key)
      - `notes` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to read and write data
*/

-- Create doctors table
CREATE TABLE IF NOT EXISTS doctors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name text NOT NULL,
  last_name text NOT NULL,
  specialty text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create patients table
CREATE TABLE IF NOT EXISTS patients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name text NOT NULL,
  last_name text NOT NULL,
  date_of_birth date NOT NULL,
  email text,
  phone text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create visits table (represents doctor-patient interactions)
CREATE TABLE IF NOT EXISTS visits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid REFERENCES patients(id) ON DELETE CASCADE,
  doctor_id uuid REFERENCES doctors(id) ON DELETE CASCADE,
  visit_date timestamptz NOT NULL DEFAULT now(),
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create diseases table
CREATE TABLE IF NOT EXISTS diseases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create visit_diagnoses table (connects visits with diagnosed diseases)
CREATE TABLE IF NOT EXISTS visit_diagnoses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  visit_id uuid REFERENCES visits(id) ON DELETE CASCADE,
  disease_id uuid REFERENCES diseases(id) ON DELETE CASCADE,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(visit_id, disease_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_doctors_name ON doctors(last_name, first_name);
CREATE INDEX IF NOT EXISTS idx_patients_name ON patients(last_name, first_name);
CREATE INDEX IF NOT EXISTS idx_visits_date ON visits(visit_date);
CREATE INDEX IF NOT EXISTS idx_diseases_name ON diseases(name);

-- Enable Row Level Security (RLS)
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE diseases ENABLE ROW LEVEL SECURITY;
ALTER TABLE visit_diagnoses ENABLE ROW LEVEL SECURITY;

-- Create policies for authenticated users
CREATE POLICY "Allow authenticated users to read doctors"
  ON doctors FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to read patients"
  ON patients FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to read visits"
  ON visits FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to read diseases"
  ON diseases FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to read visit_diagnoses"
  ON visit_diagnoses FOR SELECT
  TO authenticated
  USING (true);

-- Create policies for inserting data
CREATE POLICY "Allow authenticated users to insert doctors"
  ON doctors FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to insert patients"
  ON patients FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to insert visits"
  ON visits FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to insert diseases"
  ON diseases FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to insert visit_diagnoses"
  ON visit_diagnoses FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_doctors_updated_at
    BEFORE UPDATE ON doctors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_patients_updated_at
    BEFORE UPDATE ON patients
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_visits_updated_at
    BEFORE UPDATE ON visits
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_diseases_updated_at
    BEFORE UPDATE ON diseases
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_visit_diagnoses_updated_at
    BEFORE UPDATE ON visit_diagnoses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample data
INSERT INTO doctors (first_name, last_name, specialty) VALUES
  ('John', 'Smith', 'Cardiology'),
  ('Sarah', 'Johnson', 'Pediatrics'),
  ('Michael', 'Brown', 'Orthopedics');

INSERT INTO patients (first_name, last_name, date_of_birth, email, phone) VALUES
  ('Alice', 'Williams', '1985-03-15', 'alice@example.com', '555-0101'),
  ('Bob', 'Miller', '1990-07-22', 'bob@example.com', '555-0102'),
  ('Carol', 'Davis', '1978-11-30', 'carol@example.com', '555-0103');

INSERT INTO diseases (name, description) VALUES
  ('Hypertension', 'High blood pressure condition'),
  ('Type 2 Diabetes', 'Metabolic disorder affecting blood sugar levels'),
  ('Asthma', 'Chronic respiratory condition');

-- Create some visits
INSERT INTO visits (patient_id, doctor_id, visit_date, notes)
SELECT 
  patients.id,
  doctors.id,
  now() - interval '1 day',
  'Regular checkup'
FROM patients, doctors
WHERE patients.first_name = 'Alice'
AND doctors.first_name = 'John';

-- Add diagnoses to visits
INSERT INTO visit_diagnoses (visit_id, disease_id, notes)
SELECT 
  visits.id,
  diseases.id,
  'Initial diagnosis'
FROM visits, diseases
WHERE diseases.name = 'Hypertension'
LIMIT 1;