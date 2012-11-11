require_relative "../app/models/finger_data"

class QueriesWebFinger
  def self.query(email)
    # XXX: ensure caching of finger lookup.
    xrd = Redfinger.finger(email)
    FingerData.new(xrd)
  end
end
