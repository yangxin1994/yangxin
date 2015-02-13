class Bee

  attr_accessor :logger, :actions, :recipe, :skip_set_entrance, :timeout

  def initialize(excretion = nil)

  end
  
  def entrance()
    
  end

  def site(url)
    @site = url
  end

  def learn(recipe = nil, &block)
    if block_given?
      instance_eval(&block)
      @recipe = block
    elsif recipe.is_a?(Proc)
      instance_eval(&recipe)
      @recipe = recipe
    elsif recipe.is_a?(String)
      instance_eval(recipe)
      @recipe = recipe
    else
      self
    end
  end

  def gather_honey
    
  end
    
end