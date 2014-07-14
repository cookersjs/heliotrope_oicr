# Directives

angular
  .module 'heliotrope.directives.tables', [
    'heliotrope.services.tracker'
  ]

  .directive 'heliEntitySteps', () ->
    result =
      restrict: "A"
      replace: true
      template: '<table class="table table-bordered table-striped table-condensed">' +
                '<thead>' +
                '<tr>' +
                '<th>Date</th>' +
                '<th>Step</th>' +
                '<th>User</th>' +
                '</tr>' +
                '</thead>' +
                '<tbody class="step-body">' +
                '</tbody>' +
                '</table>'
      link: (scope, iElement, iAttrs, controller) ->
        scope.$watch 'entity', (entity) ->
          if entity
            body = iElement.find(".step-body")
            steps = entity.data.steps.sort (a, b) ->
              b.stepDate.localeCompare(a.stepDate)
            availableSteps = entity.data.availableSteps
            stepTable = {}
            stepTable[step._id] = step for step in availableSteps
            for id, step in stepTable
              step['count'] = 0
            for step in steps
              stepData = stepTable[step.stepRef]
              rowData = []
              url = entity.data.url + "/step/" + stepData["name"]
              if stepData['count']++ > 1
                url = url + ";" + stepData['count']
              rowData.push(new Date(step["stepDate"]).toLocaleDateString())
              rowData.push("<a href='" + step["url"] + "'>" + stepData["label"] + "</a>")
              rowData.push(step["stepUser"] || "anonymous")
              row = ("<td>" + element + "</td>" for element in rowData).join("")
              jQuery("<tr>" + row + "</tr>").appendTo(body)


  .directive 'heliStudyEntities', ['Study', (Study) ->
    result =
      restrict: "A"
      replace: true
      template: '<table class="table table-bordered table-striped table-condensed">' +
                '<thead>' +
                '<tr>' +
                '<th class="step-headers">XXXX</th>' +
                '</tr>' +
                '</thead>' +
                '<tbody class="step-body">' +
                '</tbody>' +
                '</table>'
      link: (scope, iElement, iAttrs, controller) ->
        scope.$watch 'study', (newValue, oldValue) ->
          if newValue
            role = iAttrs.role
            label = iAttrs.label
            header = iElement.find(".step-headers")
            body = iElement.find(".step-body")
            header.text(label)
            stepTable = {}
            stepIndex = 1
            for step in newValue.data.steps[role]
              if step.showSummary
                stepTable[step._id] = stepIndex++
                newHeader = jQuery("<th>" + step.label + "</th>")
                header.after newHeader
                header = newHeader
            query = Study.get({study: newValue.data.name, q: 'getEntities', role: role}, () ->

              for record in query.data
                row = ("" for i in [1..stepIndex])
                row[0] = "<a href='" + record.url + " '>" + record.identity + "</a>"
                for recordStep in record.steps
                  index = stepTable[recordStep.stepRef]
                  row[index] = '<span class="glyphicon glyphicon-ok"></span>' if index
                row = ("<td>" + rowData + "</td>" for rowData in row).join("")
                jQuery("<tr>" + row + "</tr>").appendTo(body)
            )
  ]

  # Add the directive for the data tables for frequencies. This could be parameterised, but encapsulates all the
  # primary logic for the frequencies table.

  .directive 'heliFrequencies', () ->
    result =
      restrict: "A"
      replace: true
      transclude: true
      scope: false
      template: '<table class="table table-bordered table-striped table-condensed">' +
                '<thead>' +
                '<tr>' +
                '<th>Tumour type</th>' +
                '<th>Frequency</th>' +
                '</tr>' +
                '</thead>' +
                '<tbody>' +
                '</tbody>' +
                '</table>'
      link: (scope, iElement, iAttrs, controller) ->
        scope.$watch 'entity.data.sections.frequencies.data.tumour', (newValue, oldValue) ->
          if (newValue && ! angular.equals(newValue, oldValue))
            renderPercent = (x) ->
              '<b>%0.2f%%</b> (%d of %d samples)'.format(x.frequency * 100.0, x.affected, x.total)
            jQuery(iElement).dataTable(
              pagingType: "bs_normal"
              paging: true
              data: angular.copy(newValue)
              columns: [
                { "title": "Tumour type", "orderable" : true, "className": "span8", "data": "tumourTypesRefx.name" }
                { "title": "Frequency", "orderable" : true, "className": "span4", "data": renderPercent }
              ]
              order: [1, 'desc']
              columnDefs: [ {
                "targets": 1,
                "type": "html-percent"
              } ]
            )
    result

  # Add the directive for the data tables for frequencies. This could be parameterised, but encapsulates all the
  # primary logic for the frequencies table.

  .directive 'heliObservations', () ->
    result =
      restrict: "A"
      replace: true
      transclude: false
      scope: false
      template: '<table class="table table-bordered table-striped table-condensed table-paginated">' +
                '<thead>' +
                '<tr>' +
                '<th>Mutation</th>' +
                '</tr>' +
                '</thead>' +
                '<tbody>' +
                '</tbody>' +
                '</table>'
      link: (scope, iElement, iAttrs, controller) ->
        scope.$watch 'entity.data.related.observations', (newValue, oldValue) ->
          if (newValue)
            jQuery(iElement).dataTable(
              pagingType: "bs_normal"
              paging: true
              lengthChange: false
              pageLength: 5
              data: newValue
              columns: [
                { "title": "Mutation", "className": "span4", "data": (data, type, val) ->
                  if type == undefined
                    data
                  else
                    "<a href='" + data.url + "'>" + data.name + "</b>"
                }
              ]
            )
    result