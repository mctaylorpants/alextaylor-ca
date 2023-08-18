use_helper Nanoc::Helpers::Blogging
use_helper Nanoc::Helpers::LinkTo
use_helper Nanoc::Helpers::Text

def article_after(current_item)
  index = sorted_articles.find_index(current_item)&.pred
  sorted_articles[index] if index && index >= 0
end

def article_before(current_item)
  index = sorted_articles.find_index(current_item)&.succ
  sorted_articles[index] if index
end
