class Dashing.Appstore extends Dashing.Widget
  ready: ->
    @onData(this)

  @accessor 'bgColor', ->
    if @get('last_version.average_rating') >= 4
      "#96bf48"
    else if @get('last_version.average_rating') >= 3
      "#ff9618"
    else if @get('last_version.average_rating') >= 0
      "#d13f3d"
    else 
      "#999999"

  @accessor 'bgImage', ->
    if @get('last_version.average_rating') >= 4
      "url('apple_green.png')"
    else if @get('last_version.average_rating') >= 3
      "url('apple_orange.png')"
    else if @get('last_version.average_rating') >= 0
      "url('apple.png')"

  onData: (data) ->
    widget = $(@node)
    widget.fadeOut().css('background-color', @get('bgColor')).css('background-png', @get('bgImage')).fadeIn()
    last_version = @get('last_version')
    rating = last_version.average_rating
    rating_detail = last_version.average_rating_detail
    voters_count = last_version.voters_count
    currentRatingStar = $(@node).find(".current-rating")
    currentRatingStar.css('width', 20 * rating + '%')
    if rating_detail then widget.find('.appstore-rating-detail-value').html( '<span id="appstore-rating-integer-value">(' + rating_detail + ')</span>')
    widget.find('.appstore-voters-count').html( '<span id="appstore-voters-count-value">' + voters_count + '</span> Votes' )