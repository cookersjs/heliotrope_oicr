# Directives

angular
  .module 'heliotrope.directives.navigation', [
    'heliotrope.services.tracker'
  ]

  # Used to generate a dropdown menu of the available workflows. These can then be
  # used to direct to a form on selection.

  .directive 'heliWorkflows', () ->
    result =
      restrict: "A"
      replace: true
      template: '<ul class="dropdown-menu">' +
                '<li ng-repeat="step in entity.data.availableSteps">' +
                '<a href="{{step.url}}">{{step.label}}</a>' +
                '</li>' +
                '</ul>'


  # To display the study menu link, make a request and see what we get. This should
  # probably be done more elegantly in the root scope, and then handled from there.

  .directive 'heliStudyMenuLink', ['StudyList', (StudyList) ->
    result =
      restrict: "A"
      replace: true
      template: '<li class="disabled"><a>studies</a></li>'
      link: (scope, iElement, iAttrs, controller) ->

        studyList = StudyList.get({}, () ->
          iElement.toggleClass("disabled")
          iElement.find('a').attr('href','/studies');
        )
  ]

  .directive 'heliKnowledgeBaseSearch', ['$http', ($http) ->
    result =
      restrict: "A"
      scope: { term: '&', entity: '&entity' }
      link: (scope, iElement, iAttrs, controller) ->
        scope.$watch "term", (newTerm) ->
          term = newTerm()
          if term
            scope.$watch "entity", (newEntity) ->
              entity = newEntity()
              if entity

                serviceUrl = entity.data.config.baseUrl + entity.data.config.knowledgeUriBase + "/variants/" + term
                frontUrl = entity.data.config.baseUrl + "/variants/" + term

                $http(
                  method: 'GET'
                  url: serviceUrl
                ).success((data, status, headers, config) ->
                  jQuery(iElement).html("<a href='" + frontUrl + "'>" + frontUrl + "</a>")
                ).error((data, status, headers, config) ->
                  jQuery(iElement).html("<span class='warn'>Not found in knowledge base</span>")
                )

  ]

  .directive 'heliSection', () ->
    result =
      restrict: "A"
      replace: true
      transclude: true
      scope: { title: '@title', id: '@bodyId', when: '=when' }
      template: '<div class="row-fluid ng-hide">' +
                '<div class="tab-content">' +
                '<div class="tab-pane active">' +
                '<div class="row-fluid">' +
                '<h3 id="{{id}}">{{title}}</h3>' +
                '</div>' +
                '<div class="body" ng-transclude></div>' +
                '</div' +
                '</div>'
      link: (scope, iElement, iAttrs, controller) ->

        navElement = jQuery("#sidebar .nav-list")
        id = iAttrs["bodyId"]
        title = iAttrs["title"]
        newElement = jQuery("<li class='ng-hide'><a class='nav-section' href='#" + id + "'>" + title + "</a></li>")
        newElement.appendTo(navElement)
        newElement.click (e) ->
          e.preventDefault()
          e.stopPropagation()
          target = e.currentTarget.firstChild.getAttribute('href')
          offset = jQuery(target).offset().top - 150
          jQuery("body").animate({scrollTop: offset}, 'slow')
          true

        ## If there's a when attribute, this is a conditional section. We should hide it
        ## any time we get a false value. This includes the TOC entry, too.
        if iAttrs.when?
          scope.$watch 'when', (value) ->
            newElement.toggleClass('ng-hide', !value?)
            jQuery(iElement).toggleClass('ng-hide', !value?)

        else
          jQuery(iElement).toggleClass('ng-hide')
          newElement.toggleClass('ng-hide')
