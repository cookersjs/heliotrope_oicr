## Copyright 2014(c) The Ontario Institute for Cancer Research. All rights reserved.
##
## This program and the accompanying materials are made available under the terms of the GNU Public
## License v3.0. You should have received a copy of the GNU General Public License along with this
## program. If not, see <http://www.gnu.org/licenses/>.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
## IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
## FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
## CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
## DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
## DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
## WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
## WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Directives

angular
  .module 'heliotrope.directives.charts', [ 'heliotrope.services.genomics' ]

  # Add the directive for the genome frequencies data, which has an optional marker
  # included for a current location. This depends on d3, and is therefore requiring an
  # svg enabled browser.
  #
  # Note that a variant is a bit different, and we ought to handle it accordingly.
  # Genes can be displayed immediately.

  .directive 'heliStructureDistribution', Array 'transformDomains', '$location', (transformDomains, $location) ->
    result =
      restrict: "A"
      replace: true
      transclude: true
      scope: false
      scope: { transcript: '=transcript', mutations: '=mutations' }
      template: '<div class="diagram"></div>'
      link: (scope, iElement, iAttrs, controller) ->

        chart = undefined
        mutationsData = undefined

        scope.$watch 'mutations', (mutations) ->
          if mutations?
            mutationsData = for m in mutations when m.codon
              {id: m.name, position: m.codon , url: "/variants/#{m.variant}", value: m.frequency, selected: m.selected}

            # Make sure selected markers are at the front. Don't use sort for this, no need. We can
            # filter and concatenate in two passes.
            mutationsSelected = mutationsData.filter (a) -> a.selected
            mutationsUnselected = mutationsData.filter (a) -> !a.selected
            mutationsData = [].concat(mutationsUnselected, mutationsSelected)

            if chart?
              chart.setMutations(mutationsData)


        scope.$watch 'transcript', (transcript) ->
          if transcript?
            domains = (domain for domain in transcript["domains"] when domain["gffSource"] == "Pfam")

            markerTooltipHtmlFn = (d) ->
              'Mutation: ' + d.id + '<br>' +
              'Number of samples: ' + d.value

            markerUrlFn = (d) ->
              jQuery(this).tooltip('hide')
              scope.$apply () ->
                $location.path(d.url)

            markerClassFn = (d) ->
              if d.selected then 'marker marker-selected' else 'marker marker-unselected'

            transcriptData =
              start: 1
              stop: transcript["lengthAminoAcid"]
              domains: transformDomains(domains)

            display = jQuery(iElement)
            chartWidth = 700
            chartHeight = 140
            element = display.get()[0]

            chartOptions =
              tooltips: false
              leftMargin: 30
              markerRadius: 6
              domainLegendBarSize: 55
              domainLegendBarDescriptionOffset: 58
              displayWidth: chartWidth
              valueHeight: chartHeight
              markerTooltipHtmlFn: markerTooltipHtmlFn
              markerUrlFn: markerUrlFn
              markerClassFn: markerClassFn

            if mutationsData?
              transcriptData['mutations'] = mutationsData

            chart = new ProteinStructureChart(chartOptions, transcriptData)
            chart.display(element)



            # domains = (domain for domain in transcript["domains"] when domain["gffSource"] == "Pfam")
            # domains = transformDomains(domains)

            # data =
            #   start: 1,
            #   stop: transcript["lengthAminoAcid"],
            #   domains: domains
        # if entityData.sections.positions
        #   positions = entityData.sections.positions
        #   codon = positions.data[0]["codon"]
        #   position = codon && parseInt((codon).toString())
        #   if ! isNaN(position)
        #     data.mutations = [{id: entityData["shortMutation"], position: position, url: null, value: 4}]

        # if entityData.sections.distribution
        #   data["background"] = entityData.sections.distribution["data"]



  .directive 'heliGeneFrequenciesBubble', () ->
    result =
      restrict: "A"
      replace: true
      transclude: true
      scope: false
      template: '<div class="diagram"></div>'
      link: (scope, iElement, iAttrs) ->
        scope.$watch 'gene.data', (genes) ->
          if genes

            display = jQuery(iElement)
            element = display.get()[0]

            chartWidth = 840
            chartHeight = 650
            color = d3.scale.category20c()

            svg = d3.select(element)
              .append("svg")
              .attr("width", chartWidth)
              .attr("height", chartHeight)
              .attr("class", "bubble")

            classes = (nodes) ->
              result = []
              for element in nodes
                result.push
                  name: element.name
                  value: element.frequency
              output =
                children: result

            bubble = d3.layout.pack()
              .sort(null)
              .size([chartWidth, chartHeight])
              .padding(1.5)

            filtered = bubble.nodes(classes(genes)).filter((d) -> !d.children)

            nodes = svg.selectAll(".bubble")
              .data(filtered)
              .enter()
              .append("g")
              .attr("class", "bubble")
              .attr("transform", (d) -> "translate(#{d.x},#{d.y})")

            nodes.append("title")
              .text((d) -> d.name)

            links = nodes.append("a")
              .attr("xlink:href", (d) -> "genes/" + d.name)

            links.append("circle")
              .attr("r", (d) -> d.r)
              .style("fill", (d) -> color(d.name))

            links.append("text")
              .attr("dy", ".3em")
              .style("text-anchor", "middle")
              .style("font-size", (d) -> d.r / 2)
              .text((d) -> d.name)


  .directive 'heliGeneFrequencies', () ->
    result =
      restrict: "A"
      replace: true
      transclude: true
      scope: false
      template: '<div class="diagram"></div>'
      link: (scope, iElement, iAttrs, controller) ->
        scope.$watch 'gene.data', (newValue, oldValue) ->
          if (newValue)

            display = jQuery(iElement)

            # console.debug newValue

            data = newValue.slice(0, 30)

            chartWidth = 760
            chartHeight = 600

            margin = {top: 20, right: 20, bottom: 30, left: 80}
            width = chartWidth - margin.left - margin.right
            height = chartHeight - margin.top - margin.bottom

            formatPercent = d3.format(".0%");

            x = d3.scale.linear().range([0, width])
            y = d3.scale.ordinal().rangeRoundBands([0, height], 0.1)

            xAxis = d3.svg.axis().scale(x).orient("top").tickFormat(formatPercent)
            yAxis = d3.svg.axis().scale(y).orient("left")

            x.domain([0, d3.max(data, (d) -> d.frequency.frequency)])
            y.domain(data.map((d) -> d.name))

            element = display.get()[0]
            svg = d3.select(element)
              .append("svg")
              .attr("class", "chart")
              .attr("width", width + margin.left + margin.right)
              .attr("height", height + margin.top + margin.bottom)
              .append("g")
              .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

            svg.append("g")
              .attr("class", "x axis")
              .call(xAxis)

            svg.append("g")
              .attr("class", "y axis")
              .call(yAxis)
              .append("text")
              .attr("transform", "rotate(-90)")
              .attr("y", 6)
              .attr("dy", ".71em")

      #      console.debug data

            node = svg.selectAll(".bar")
              .data(data)
              .enter()
              .append("a")
              .attr("xlink:href", (d) -> "genes/" + d.name)

            node.append("rect")
              .attr("class", "bar")
              .attr("x", 0.5)
              .attr("y", (d) -> y(d.name))
              .attr("width", (d) -> x(d.frequency.frequency))
              .attr("height", y.rangeBand())
