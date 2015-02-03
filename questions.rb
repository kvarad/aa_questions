require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database

  include Singleton

  def initialize
    super('questions.db')

    self.results_as_hash = true
    self.type_translation = true
  end
end

class User
  attr_accessor :id, :f_name, :l_name

  def initialize(results = {})
    @id = results['id']
    @f_name = results['f_name']
    @l_name = results['l_name']
  end

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        users.id = ?
    SQL

    results.map { |result| User.new(result) }
  end

  def self.find_by_name(f_name, l_name)
    results = QuestionsDatabase.instance.execute(<<-SQL, f_name, l_name)
      SELECT
        *
      FROM
        users
      WHERE
        users.f_name = ? AND users.l_name = ?
    SQL

    results.map { |result| User.new(result) }
  end

  def authored_questions

    Question.find_by_author_id(id)

  end

  def authored_replies
    Reply.find_by_user_id(id)
  end

  def followed_questions
    QuestionFollower.followed_questions_for_user_id(id)
  end

  def liked_questions
    QuestionLikes.liked_questions_for_user_id(id)
  end

  def average_karma
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        COUNT(CAST(question_likes.question_id AS FLOAT)) / COUNT(DISTINCT(questions.id))
      FROM
        questions LEFT OUTER JOIN question_likes
        ON questions.id = question_likes.question_id
      WHERE
        questions.user_id = ?
    SQL
    results.first.values.first
  end

  def save
    if id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, f_name, l_name)
        INSERT INTO
        users (f_name, l_name)
        VALUES
        (?, ?)
      SQL
        @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, f_name, l_name, id)
      UPDATE users
        SET f_name=?, l_name=?
        WHERE id = ?
      SQL
    end
  end
end

class Question
  attr_accessor :id, :title, :body, :user_id

  def initialize(options = {})
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
  end

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
      *
      FROM
      questions
      WHERE
      questions.id = ?
    SQL

    results.map { |result| Question.new(result) }
  end

  def self.find_by_author_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        questions
      WHERE
        questions.user_id = ?
      SQL

      results.map { |result| Question.new(result) }
    end

    def self.most_followed(n)
      QuestionFollower.most_followed_questions(n)
    end

  def author

    User.find_by_id(user_id)

  end

  def replies(id = id)
    Reply.find_by_question_id(id)
  end

  def followers
    QuestionFollower.followers_for_question_id(id)
  end

  def likers
    QuestionLike.likers_for_question_id(id)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def num_likes
    QuestionLike.num_likes_for_question(id)
  end

  def save
    if id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, title, body, user_id)
        INSERT INTO
        questions (title, body, user_id)
        VALUES
        (?, ?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, title, body, user_id, id)
        UPDATE questions
        SET title=?, body=?, user_id=?
        WHERE id = ?
      SQL
    end
  end
end

class QuestionFollower
  attr_accessor :id, :question_id, :user_id

  def initialize(options = {})
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
    *
    FROM
    question_folowers
    WHERE
    question_followers.id = ?
    SQL

    results.map { |result| QuestionFollower.new(result) }
  end

  def self.followers_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.id, users.f_name, users.l_name
      FROM
        question_followers JOIN users
        ON question_followers.user_id = users.id
      WHERE
        question_followers.question_id = ?
    SQL

    results.map { |result| User.new(result) }
  end

  def self.followed_questions_for_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id, questions.title, questions.body, questions.user_id
      FROM
        question_followers JOIN questions
        ON question_followers.question_id = questions.id
      WHERE
        question_followers.user_id = ?
    SQL

    results.map { |result| Question.new(result) }
  end

  def self.most_followed_questions(n)
    results = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.id, questions.title, questions.body, questions.user_id
      FROM
        questions JOIN question_followers
        ON questions.id = question_followers.question_id
      GROUP BY questions.id
      ORDER BY COUNT(questions.id) DESC
      LIMIT ?
    SQL
    results.map { |result| Question.new(result) }
  end
end

class Reply
  attr_accessor :id, :body, :question_id, :parent_id, :user_id

  def initialize(options = {})
    @id = options['id']
    @body = options['body']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
    @user_id = options['user_id']
  end

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
    *
    FROM
    replies
    WHERE
    replies.id = ?
    SQL

    results.map { |result| Reply.new(result) }
  end

  def self.find_by_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.question_id = ?
    SQL

    results.map { |result| Reply.new(result) }
  end

  def self.find_by_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.user_id = ?
    SQL

    results.map { |result| Reply.new(result) }
  end

  def author
    User.find_by_id(user_id)
  end

  def question
    Question.find_by_id(question_id)
  end

  def parent_reply
    Reply.find_by_id(parent_id)
  end

  def child_replies
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.parent_id = ?
    SQL

    results.map { |result| Reply.new(result) }
  end

  def save
    if id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, body, question_id, parent_id, user_id)
        INSERT INTO
        replies (body, question_id, parent_id, user_id)
        VALUES
        (?, ?, ?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, body, question_id, parent_id, user_id, id)
        UPDATE replies
        SET body=?, question_id=?, parent_id=?, user_id=?
        WHERE id = ?
      SQL
    end
  end
end

class QuestionLike
  attr_accessor :id, :question_id, :user_id

  def initialize(options = {})
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
    *
    FROM
    question_likes
    WHERE
    question_likes.id = ?
    SQL

    results.map { |result| QuestionLike.new(result) }
  end

  def self.likers_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.id, users.f_name, users.l_name
      FROM
        question_likes JOIN users ON question_likes.user_id = users.id
      WHERE
        question_likes.question_id = ?
    SQL

    results.map { |result| User.new(result) }
  end

  def self.num_likes_for_question(question_id)
    result = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(*)
      FROM
        question_likes
      WHERE
        question_likes.question_id = ?
    SQL

    result.first.values.first
  end

  def self.liked_questions_for_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id, questions.title, questions.body, questions.user_id
      FROM
        question_likes JOIN questions
        ON question_likes.question_id = questions.id
      WHERE
        question_likes.user_id = ?
    SQL
    results.map { |result| Question.new(result) }
  end

  def self.most_liked_questions(n)
    results = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
      questions.id, questions.title, questions.body, questions.user_id
      FROM
      questions JOIN question_likes
      ON questions.id = question_likes.question_id
      GROUP BY questions.id
      ORDER BY COUNT(questions.id) DESC
      LIMIT ?
    SQL
    results.map { |result| Question.new(result) }
  end
end
