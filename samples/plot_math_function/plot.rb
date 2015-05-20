require 'pilot-gnuplot'
include Gnuplot

plot = Plot.new(['x*sin(x)', with: 'lines', lw: 4], xrange: -10..10, title: 'Math function example', ylabel: 'x', xlabel: 'x*sin(x)', term: ['qt', persist: true])

$RSPEC_TEST ? plot.to_png('./gnuplot_gem.png', size: [600, 600]) : plot.plot