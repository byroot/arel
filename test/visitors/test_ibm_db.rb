require 'helper'

module Arel
  module Visitors
    describe 'the ibm_db visitor' do
      before do
        @visitor = IBM_DB.new Table.engine.connection
      end

      it 'uses FETCH FIRST n ROWS to limit results' do
        stmt = Nodes::SelectStatement.new
        stmt.limit = Nodes::Limit.new(1)
        sql = @visitor.accept(stmt)
        sql.must_be_like "SELECT FETCH FIRST 1 ROWS ONLY"
      end

      it 'uses FETCH FIRST n ROWS in updates with a limit' do
        table = Table.new(:users)
        stmt = Nodes::UpdateStatement.new
        stmt.relation = table
        stmt.limit = Nodes::Limit.new(Nodes.build_quoted(1))
        stmt.key = table[:id]
        sql = @visitor.accept(stmt)
        sql.must_be_like "UPDATE \"users\" WHERE \"users\".\"id\" IN (SELECT \"users\".\"id\" FROM \"users\" FETCH FIRST 1 ROWS ONLY)"
      end

    end
  end
end
