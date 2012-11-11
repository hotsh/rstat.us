class FingerData
  def initialize(xrd)
    @xrd = xrd
  end

  def url
    find('http://schemas.google.com/g/2010#updates-from')
  end

  def public_key
    public_key = find('magic-public-key')
    public_key.split(",")[1] || ""
  end

  def salmon_url
    find('salmon')
  end

  private

  def find(rel)
    element_hash = links.find { |link| link['rel'].downcase == rel } || {}
    element_hash.fetch("href") { "" }
  end

  def links
    @xrd.links || []
  end
end
