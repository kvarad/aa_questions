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
end

class Question
  attr_accessor :id, :title, :body, :user_id

  def initialize(results = {})
    @id = results['id']
    @title = results['title']
    @body = results['body']
    @user_id = results['user_id']
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
end

class QuestionFollower
  attr_accessor :id, :question_id, :user_id

  def initialize(results = {})
    @id = results['id']
    @question_id = results['question_id']
    @user_id = results['user_id']
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
end

class Reply
end

class QuestionLike
end
