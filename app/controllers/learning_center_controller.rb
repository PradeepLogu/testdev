class LearningCenterController < ApplicationController
  
  def index
  	@lc = LearningCenter.new
  	@tips_and_tricks = @lc.tips_and_tricks_posts
    @most_recent_post = @lc.most_recent_post
  end

  def faq
  	@lc = LearningCenter.new
  	@faq = @lc.faq

    @categories = @lc.subcategories_by_category_name(@lc.faq_category_name)
    @cur_category = @categories.first
  end

  def glossary
  	@lc = LearningCenter.new
  	@glossary = LearningCenter::Glossary.new(@lc)
    @alphabet_array = @glossary.alphabet_array(false)
  end

  def tire_size
  	@lc = LearningCenter.new
  	@tire_size = []
  end

end
