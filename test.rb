require 'neo4j'
require 'rspec'
require 'pry'

class User < Neo4j::Model
end


class UserGroup < Neo4j::Model
  property :name
  has_n(:users)
end

class Company < Neo4j::Model
  has_one(:primary_user)
  has_n(:groups)

  def admin_group
    groups.find{|g| g.name == 'admin'}
  end

  def admins
    admin_group.users
  end

  def users
    admins
  end


  validates :primary_user,    :presence => true

  before_validation :ensure_primary_user_is_part_of_company

  protected

  def ensure_primary_user_is_part_of_company
    g = admin_group
    self.groups << (g = UserGroup.new(:name => 'admin')) unless g
    g.users << primary_user
  end
end


u1, u2 = User.create!, User.create!

company = Company.create(:primary_user => u1)
company.primary_user = u2
company.save!

company.admin_group.persisted?.should == true

company = company.reload
company.primary_user.should == u2

company.users.count.should == 2
company.users.include?(u1).should == true
company.users.include?(u2).should == true

