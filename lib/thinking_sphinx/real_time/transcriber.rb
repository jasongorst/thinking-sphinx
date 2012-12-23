class ThinkingSphinx::RealTime::Transcriber
  def initialize(index)
    @index = index
  end

  def copy(instance)
    ThinkingSphinx::Connection.pool.take do |connection|
      return unless copy? instance

      columns, values = ['id'], [index.document_id_for_key(instance.id)]
      (index.fields + index.attributes).each do |property|
        columns << property.name
        values  << property.translate(instance)
      end

      sphinxql = Riddle::Query::Insert.new index.name, columns, values
      connection.execute sphinxql.replace!.to_sql
    end
  end

  private

  attr_reader :index

  def copy?(instance)
    index.conditions.all? { |condition|
      case condition
      when Symbol
        instance.send(condition)
      when Proc
        condition.call instance
      else
        "Unexpected condition: #{condition}. Expecting Symbol or Proc."
      end
    }
  end
end
