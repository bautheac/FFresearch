
[![Travis-CI Build Status](https://travis-ci.org/bautheac/FFresearch.svg?branch=master)](https://travis-ci.org/bautheac/FFresearch)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/bautheac/FFresearch?branch=master&svg=true)](https://ci.appveyor.com/project/bautheac/FFresearch)
[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)

# FFresearch

Fama/French research data conveniently packaged for consumption by R users. The data is pulled directly from Kenneth French's online [data library](http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html). Size concerns limit the data history to the last twenty years; 
the full time series are available from the author upon request.

## Installation

Install the development version from [github](https://github.com/bautheac/FFresearch/) with:

``` r
devtools::install_github(repo = "FFresearch", username = "bautheac")
```

## Example

Classic Fama & French asset pricing factors

``` r
library(FFresearch)
data(list = c("factors"), package = "FFresearch", envir = environment())
```
