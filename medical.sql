/*
  # Medical Center Database Schema
*/

-- Create doctors table
CREATE TABLE IF NOT EXISTS doctors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  specialty text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create patients table
CREATE TABLE IF NOT EXISTS patients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  date_of_birth date NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create visits table
CREATE TABLE IF NOT EXISTS visits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id uuid REFERENCES doctors(id) ON DELETE CASCADE NOT NULL,
  patient_id uuid REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  visit_date timestamptz NOT NULL DEFAULT now(),
  notes text,
  created_at timestamptz DEFAULT now()
);

-- Create diseases table
CREATE TABLE IF NOT EXISTS diseases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text,
  created_at timestamptz DEFAULT now()
);

-- Create visit_diagnoses table (junction table for visits and diseases)
CREATE TABLE IF NOT EXISTS visit_diagnoses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  visit_id uuid REFERENCES visits(id) ON DELETE CASCADE NOT NULL,
  disease_id uuid REFERENCES diseases(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(visit_id, disease_id)
);

-- Enable Row Level Security
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE diseases ENABLE ROW LEVEL SECURITY;
ALTER TABLE visit_diagnoses ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow authenticated read access" ON doctors
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated read access" ON patients
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated read access" ON visits
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated read access" ON diseases
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated read access" ON visit_diagnoses
  FOR SELECT TO authenticated USING (true);

-- Insert sample data
INSERT INTO doctors (name, specialty) VALUES
  ('Dr. Jane Smith', 'Cardiology'),
  ('Dr. John Doe', 'Pediatrics');

INSERT INTO patients (name, date_of_birth) VALUES
  ('Alice Johnson', '1990-05-15'),
  ('Bob Wilson', '1985-03-22');

INSERT INTO diseases (name, description) VALUES
  ('Hypertension', 'High blood pressure condition'),
  ('Common Cold', 'Viral upper respiratory tract infection');

INSERT INTO visits (doctor_id, patient_id, visit_date, notes)
SELECT 
  d.id,
  p.id,
  now(),
  'Regular checkup'
FROM doctors d, patients p
WHERE d.name = 'Dr. Jane Smith' AND p.name = 'Alice Johnson';

INSERT INTO visit_diagnoses (visit_id, disease_id)
SELECT 
  v.id,
  d.id
FROM visits v, diseases d
WHERE d.name = 'Hypertension'
LIMIT 1;