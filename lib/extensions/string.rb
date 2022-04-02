class String
  def number?
    true if Integer(self) rescue false
  end
end
