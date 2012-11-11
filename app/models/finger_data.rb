class FingerData
  def initialize(xrd)
    @xrd = xrd
  end

  def url
    @xrd.links.find { |l| l['rel'] == 'http://schemas.google.com/g/2010#updates-from' }.to_s
  end

  def public_key
    public_key_href = @xrd.links.find { |l| l['rel'].downcase == 'magic-public-key' }.href
    public_key_href[/^.*?,(.*)$/,1]
  end

  def salmon_url
    @xrd.links.find { |l| l['rel'].downcase == 'salmon' }.href
  end
end
