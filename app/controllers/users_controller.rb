require 'csv'

class UsersController < ApplicationController

  load_and_authorize_resource param_method: :user_params 
  before_action :require_permission, except: [:download_sample_file]
  before_action :load_user , only:[:show, :edit, :update]
  before_action :load_company, except: [:download_invalid_csv,
    :download_invalid_xls, :download_invalid_xlsx, :download_sample_file]

  respond_to :html, :json

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Employees", :company_users_path, only: [:index, :search]
  add_breadcrumb "Employee Detail", :user_path, only: [:show]


  def new
    @company = Company.new
    @user = @company.employees.build
  end

  def create
    @user = @company.employees.build(:name => user_params[:name],
     :email => user_params[:email], :mobile_number => user_params[:mobile_number],
      :is_active =>true, :role => "employee",:password=> Devise.friendly_token.first(8))

    if @user.valid?
      @user.save
      flash[:success] = "Employee record added!!"
      # redirect_to company_users_path
    else
      flash.now[:error]=  @user.errors.messages
      render :new 
    end
  end

  def index
    @users = @company.employees.includes(:company).where(role: "employee").order(:created_at).page(params[:page]).per(4)
    add_breadcrumb @company.name, company_users_path
  end
  
  def update
    page = 1
    if !params[:page]
      params[:page] = page
    end
    if @user.update(user_params)
      flash[:success] = "Status changed successfully!!"
      redirect_to company_users_path(@company,:page=>params[:page])
    else
      flash.now[:error]= @user.errors.messages
    end
  end



  def import
  end

  def add_multiple_employee_records
    
    result = User.import(params[:file], params[:company_id])
    if result == 1
      redirect_to company_users_path(params[:company_id]), notice: "User records imported"
    else result == 0
      redirect_to company_users_path(params[:company_id]), notice: "Invalid record! Click Invalid Records to download file!!!"
    end
  end

  def search
    search_value = params[:search_value].downcase
    @users = @company.employees.includes(:company).where(role: "employee").where("lower(name) like ? or
     lower(email) like ?", "%#{search_value}%","%#{search_value}%").all.
     order('created_at').page(params[:page]).per(5)
    if @users.empty?
      render "index"
      # redirect_to company_users_path(params[:company_id])
    else
      add_breadcrumb "Search Results"
    end  
  end

  
  def download_sample_file
    file_type = params[:file_type]

    case file_type
    when 'csv' then 
      send_file("#{Rails.root}/public/employees.csv",
        type: "application/csv")
    when 'xls' then 
      send_file("#{Rails.root}/public/employees.xls",
        type: "application/xls") 
    when 'xlsx' then 
      send_file("#{Rails.root}/public/employees.xlsx",
        type: "application/xlsx")
    # else raise "Unknown file type: #{file.original_filename}"
    end
  end


  def user_params
    params.require(:user).permit(:id,:name,:email,:is_active,:mobile_number, :password)
  end

  
  private

  def load_user
    @user = User.find(params[:id])
  end

  def load_company
    @company = Company.find(params[:company_id])  
  end

  def require_permission
    unless current_user.in?(Company.find(params[:company_id])
                                   .employees
                                   .where(role: "company_admin"))
      flash[:error] = "You are not authorized to access it!!"
      redirect_to vendors_path
    end
  end

end
