
require 'csv'

class CatalogsController < ApplicationController
  # GET /catalogs
  # GET /catalogs.xml
  def index
    @catalogs = Catalog.all
    @catalog_types = CatalogType.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @catalogs }
    end
  end

  # GET /catalogs/1
  # GET /catalogs/1.xml
  def show
    @catalog = Catalog.find(params[:id])

    if params.has_key?(:node)
     nodeid=params[:node]
     if nodeid=="0"
        @shownode=@catalog.root_node
     else
       node=Node.find nodeid
        @shownode=node
     end
    end
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :partial => 'tree.js.erb' ,
        :locals => { :checkbox => params.has_key?('checkbox')?params['checkbox']:'false' } }
    end

  end

  # GET /catalogs/new
  # GET /catalogs/new.xml
  def new
    @catalog = Catalog.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @catalog }
    end
  end

  # GET /catalogs/1/edit
  def edit
    @catalog = Catalog.find(params[:id])
  end

  # POST /catalogs
  # POST /catalogs.xml
  def create
    file = params[:catalog][:dump]
    params[:catalog].delete(:dump)
    @catalog = Catalog.new( params[:catalog])
    importer=ImporterManager.instance.import_methods[@catalog.catalog_type.import_method]
    if file
        begin
          importer.import @catalog,file
        rescue
         @catalog.errors.add_to_base t("admin.catalog.errors.import_file_invalid")
        end
        
    else
      if importer.class!=Importer::DummyCatalogImporter
       @catalog.errors.add_to_base t("admin.catalog.errors.import_file_not_blank")
      else
        importer.import @catalog
      end
    end
     
    respond_to do |format|
      if @catalog.errors.empty?
        flash[:notice] = 'Catalog was successfully created.'
        if(!@catalog.catalog_type.active_catalog)
            @catalog.catalog_type.active_catalog_id = @catalog.id
            @catalog.catalog_type.save
        end
        format.html { redirect_to(@catalog) }
        format.xml  { render :xml => @catalog, :status => :created, :location => @catalog }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @catalog.errors, :status => :unprocessable_entity }
      end

     
    end
  end

  # PUT /catalogs/1
  # PUT /catalogs/1.xml
  def update
    @catalog = Catalog.find(params[:id])

    respond_to do |format|
      if @catalog.update_attributes(params[:catalog])
        flash[:notice] = 'Catalog was successfully updated.'
        format.html { redirect_to(@catalog) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @catalog.errors, :status => :unprocessable_entity }
      end
    end
  end


 


  # DELETE /catalogs/1
  # DELETE /catalogs/1.xml
  def destroy
    @catalog = Catalog.find(params[:id])
    @catalog.destroy

    respond_to do |format|
      format.html { redirect_to(catalogs_url) }
      format.xml  { head :ok }
    end
  end

  def activate
    @catalog = Catalog.find(params[:id])
    @catalog.catalog_type.active_catalog_id = @catalog.id
    @catalog.catalog_type.save
    respond_to do |format|
      flash[:notice] = 'Catalog was activated.'
      format.html { redirect_to(catalogs_url) }
      format.xml  { head :ok }
    end
  end

  def add_field_entry
     @catalog = Catalog.find(params[:id])

  end

  def edit_field_entry
    @catalog = Catalog.find(params[:id])
    if params[:node_to_edit]!=""
    @edit_field_entry=Entry.find(params[:node_to_edit])
     respond_to do |format|
       if params.has_key?("delete_field_entry")
          @edit_field_entry.destroy
          flash[:notice] = t('admin.catalog.user_defined.destroy_field_entry.ok')
           format.html { redirect_to(@catalog) }
        else
           format.html { render :action => "edit_field_entry" }
        end
      end
    else
      redirect_to(@catalog)
    end

  end

  def update_field_entry
      @catalog = Catalog.find(params[:id])
      @edit_field_entry=Entry.find(params[:node_to_edit])
      @edit_field_entry.name= params[:name]
      @edit_field_entry.description= params[:description]
     respond_to do |format|
      if  @edit_field_entry.save
        flash[:notice] = t('admin.catalog.user_defined.update_field_entry.ok')
        format.html { redirect_to(@catalog) }
        format.xml  { head :ok }

      else
        flash[:error] = t('admin.catalog.user_defined.update_field_entry.error')
         format.html { render :action => "add_field_entry" }
         format.xml  { head :error  }
      end
     end
  end

  def create_field_entry
    @catalog = Catalog.find(params[:id])
    code= Time.new.strftime("%Y-%m-%d/%H:%M")
    name= params[:name]
    description= params[:description]
    fieldentry=FieldEntry.new(:code => code, :name => name, :description => description, :node_id => @catalog.root_node.id)
    respond_to do |format|
    if fieldentry.save
      FieldDefinition.create(:input_type => 0, :field_entry_id => fieldentry.id)
      flash[:notice] = t('admin.catalog.user_defined.create_field_entry.ok')
      format.html { redirect_to(@catalog) }
      format.xml  { head :ok }
      
    else
      flash[:error] = t('admin.catalog.user_defined.create_field_entry.error')
       format.html { render :action => "add_field_entry" }
       format.xml  { head :error  }
    end
    end
  end

end

