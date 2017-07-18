class Dashing.PlayRatings extends Dashing.Widget
  ready: ->
    @onData(this)

  @accessor 'bgColor', ->
    if @get('last_version.average_rating') >= 4
      "#96bf48"
    else if @get('last_version.average_rating') >= 3
      "#ff9618"
    else if @get('last_version.average_rating') >= 0
      "#D26771"
    else 
      "#999999"

  @accessor 'bgImage', ->
    if @get('last_version.average_rating') >= 4
      'android_green.png'
    else if @get('last_version.average_rating') >= 3
      'android_orange.png'
    else
      'android.png'

  onData: (data) ->
    widget = $(@node)
    widget.fadeOut().css('background-color', @get('bgColor')).css('background-png', @get('bgImage')).fadeIn()
    last_version = @get('last_version')
    rating = last_version.average_rating
    rating_detail = last_version.average_rating_detail
    voters_count = last_version.voters_count
    currentRatingStar = $(@node).find(".current-rating")
    currentRatingStar.css('width', 20 * rating + '%')
    if rating_detail then widget.find('.google-rating-detail-value').html( '<span id="google-rating-integer-value">(' + rating_detail + ')</span>')
    widget.find('.google-voters-count').html( '<span id="google-voters-count-value">' + voters_count + '</span> Votes' )
   