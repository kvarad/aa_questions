CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  f_name VARCHAR(50) NOT NULL,
  l_name VARCHAR(50) NOT NULL
);

CREATE TABLE questions(
  id INTEGER PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  body VARCHAR(500) NOT NULL,
  user_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_followers(
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE replies(
  id INTEGER PRIMARY KEY,
  body VARCHAR(500) NOT NULL,
  question_id INTEGER NOT NULL,
  parent_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes(
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO
  users (f_name, l_name)
VALUES
  ('Jake', 'Shorty'),
  ('Karthik', 'Raj');


INSERT INTO
  questions (title, body, user_id)
VALUES
  ('Help', 'What is the meaning of life?',
    (SELECT id FROM users WHERE f_name = 'Jake' AND l_name = 'Shorty')),
  ('Recursion Help', 'I cannot get Fibonacci to work!?',
    (SELECT id FROM users WHERE f_name = 'Karthik' AND l_name = 'Raj'));
