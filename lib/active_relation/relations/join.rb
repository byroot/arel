module ActiveRelation
  class Join < Relation
    attr_reader :join_sql, :relation1, :relation2, :predicates

    def initialize(join_sql, relation1, relation2, *predicates)
      @join_sql, @relation1, @relation2, @predicates = join_sql, relation1, relation2, predicates
    end

    def ==(other)
      self.class == other.class       and
      predicates == other.predicates  and (
        (relation1 == other.relation1 and relation2 == other.relation2) or
        (relation2 == other.relation1 and relation1 == other.relation2)
      )
    end

    def qualify
      descend(&:qualify)
    end
    
    def attributes
      (externalize(relation1).attributes +
        externalize(relation2).attributes).collect { |a| a.bind(self) }
    end
    
    def prefix_for(attribute)
      externalize(relation1).prefix_for(attribute) or
      externalize(relation2).prefix_for(attribute)
    end

    def descend(&block)
      Join.new(join_sql, relation1.descend(&block), relation2.descend(&block), *predicates.collect(&block))
    end
    
    protected
    def joins
      this_join = [
        join_sql,
        externalize(relation2).table_sql,
        "ON",
        predicates.collect { |p| p.bind(self).to_sql(Sql::Predicate.new) }.join(' AND ')
      ].join(" ")
      [relation1.joins, relation2.joins, this_join].compact.join(" ")
    end

    def selects
      externalize(relation1).selects + externalize(relation2).selects
    end
   
    def table_sql
      externalize(relation1).table_sql
    end
    
    private
    def externalize(relation)
      Externalizer.new(relation)
    end
    
    Externalizer = Struct.new(:relation) do
      def table_sql
        relation.aggregation?? relation.to_sql(Sql::Aggregation.new) : relation.send(:table_sql)
      end
      
      def selects
        relation.aggregation?? [] : relation.send(:selects)
      end
      
      def attributes
        relation.aggregation?? relation.attributes.collect(&:to_attribute) : relation.attributes
      end
      
      def prefix_for(attribute)
        if relation[attribute]
          relation.alias?? relation.alias : relation.prefix_for(attribute)
        end
      end
    end
  end
end