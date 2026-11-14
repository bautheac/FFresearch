FFresearch
================

[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)

<style> body {text-align: justify} </style>

[FFresearch](https://github.com/bautheac/FFresearch/) packages
Fama/French research data for convenient consumption by R users. The
data is pulled directly from Kenneth French’s online [data
library](https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html).  
Install from [github](https://github.com/bautheac/FFresearch/) with
`devtools::install_github("bautheac/FFresearch")`.

### Portfolios

#### Univariate

The `portfolios_univariate` dataset provides various feature time series
for Fama/French portfolios formed on single variable sorts. Sorting
variables include size, book-to-market, operating profitability and
investment:

    #>    region frequency         sort variable dividend weights portfolio  field
    #>    <fctr>    <fctr>                <fctr>   <fctr>  <fctr>    <char> <fctr>
    #> 1:     US       day market capitalization        Y   value     Dec 2 return
    #> 2:     US       day market capitalization        Y   value     Dec 2 return
    #> 3:     US       day market capitalization        Y   value     Dec 2 return
    #> 4:     US       day market capitalization        Y   value     Dec 2 return
    #> 5:     US       day market capitalization        Y   value     Dec 2 return
    #> 6:     US       day market capitalization        Y   value     Dec 2 return
    #>      period value
    #>      <char> <num>
    #> 1: 19260701 -0.13
    #> 2: 19260702 -0.40
    #> 3: 19260706  0.61
    #> 4: 19260707 -0.10
    #> 5: 19260708 -0.90
    #> 6: 19260709  0.77

#### Bivariate

The `portfolios_bivariate` dataset provides various feature time series
for Fama/French portfolios formed on two variable sorts. Sorting
variables include size, book-to-market, operating profitability and
investment. The full history is shipped, from 1926 for US sorts and July
1990 for the regional sorts (developed, developed (ex US), Europe, JP,
Asia-Pacific (ex JP) and North America), through September 2026.

    #>    region frequency       sort variable 1 sort variable 2 dividend weights
    #>    <fctr>    <fctr>                <fctr>          <fctr>   <fctr>  <fctr>
    #> 1:     US       day market capitalization     book/market        Y   value
    #> 2:     US       day market capitalization     book/market        Y   value
    #> 3:     US       day market capitalization     book/market        Y   value
    #> 4:     US       day market capitalization     book/market        Y   value
    #> 5:     US       day market capitalization     book/market        Y   value
    #> 6:     US       day market capitalization     book/market        Y   value
    #>    portfolio  field   period value
    #>       <char> <fctr>   <char> <num>
    #> 1:  BIG HiBM return 19370701 -0.64
    #> 2:  BIG HiBM return 19370702  1.37
    #> 3:  BIG HiBM return 19370706  6.43
    #> 4:  BIG HiBM return 19370707  1.96
    #> 5:  BIG HiBM return 19370708  3.29
    #> 6:  BIG HiBM return 19370709 -2.38

#### Trivariate

The `portfolios_trivariate` dataset provides various feature time series
for Fama/French portfolios formed on three variable sorts. Sorting
variables include size, book-to-market, operating profitability and
investment:

    #>    region frequency       sort variable 1 sort variable 2
    #>    <fctr>    <fctr>                <fctr>          <fctr>
    #> 1:     US     month market capitalization     book/market
    #> 2:     US     month market capitalization     book/market
    #> 3:     US     month market capitalization     book/market
    #> 4:     US     month market capitalization     book/market
    #> 5:     US     month market capitalization     book/market
    #> 6:     US     month market capitalization     book/market
    #>            sort variable 3 dividend weights     portfolio  field period   value
    #>                     <fctr>   <fctr>  <fctr>        <char> <fctr> <char>   <num>
    #> 1: operating profitability        Y   value BIG HiBM.HiOP return 196307 -0.6775
    #> 2: operating profitability        Y   value BIG HiBM.HiOP return 196308  8.1046
    #> 3: operating profitability        Y   value BIG HiBM.HiOP return 196309 -2.4192
    #> 4: operating profitability        Y   value BIG HiBM.HiOP return 196310  2.8136
    #> 5: operating profitability        Y   value BIG HiBM.HiOP return 196311  1.1559
    #> 6: operating profitability        Y   value BIG HiBM.HiOP return 196312 -1.1745

#### Industries

The `portfolios_industries` dataset provides various feature time series
for Fama/French industry portfolios (Fama and French 1997):

    #>    region frequency dividend weights portfolio  field period  value
    #>    <fctr>    <fctr>   <fctr>  <fctr>    <char> <fctr> <char>  <num>
    #> 1:     US     month        Y   value      Aero return 192607  -0.65
    #> 2:     US     month        Y   value      Aero return 192608  -6.59
    #> 3:     US     month        Y   value      Aero return 192609  -7.09
    #> 4:     US     month        Y   value      Aero return 192610 -13.36
    #> 5:     US     month        Y   value      Aero return 192611   6.56
    #> 6:     US     month        Y   value      Aero return 192612   9.17

### Factors

The `factors` dataset provides the return (factors) and level (risk free
rate) time series for the classic Fama/French asset pricing factors as
used in their three (Fama and French 1992, 1993, 1995) and most recently
five-factor (Fama and French 2015, 2016, 2017) asset pricing models
extremely popular to the asset pricing enthusiasts:

    #>    region frequency factor period value
    #>    <fctr>    <fctr> <char> <char> <num>
    #> 1:     US     month    CMA 196307 -1.15
    #> 2:     US     month    CMA 196308 -0.38
    #> 3:     US     month    CMA 196309  0.15
    #> 4:     US     month    CMA 196310 -2.25
    #> 5:     US     month    CMA 196311  2.27
    #> 6:     US     month    CMA 196312 -0.25

### Variables

The `variables` dataset is a helper dataset that provides details,
including construction methods, for the variables used to construct the
portfolios and asset pricing factors above:

    #> # A tibble: 6 × 3
    #>   name                    symbol description                                    
    #>   <chr>                   <chr>  <chr>                                          
    #> 1 market capitalization   ME     Market equity (size) is price times shares out…
    #> 2 book value              BE     Book equity is constructed from Compustat data…
    #> 3 book/market             ME/BE  The book-to-market ratio used to form portfoli…
    #> 4 operating profitability OP     The operating profitability ratio used to form…
    #> 5 investment              INV    The investment ratio used to form portfolios i…
    #> 6 earnings/price          E/P    Earnings is total earnings before extraordinar…

### Breakpoints

The `breakpoints` dataset is a helper dataset that provides the times
series for the variables breakpoints used to construct the variables
that in turn allow the construction of the portfolios and asset pricing
factors abovementioned:

    #>    variable frequency percentile period value
    #>      <fctr>    <fctr>     <fctr> <char> <num>
    #> 1:     size     month # positive 192512   488
    #> 2:     size     month # positive 192601   492
    #> 3:     size     month # positive 192602   500
    #> 4:     size     month # positive 192603   503
    #> 5:     size     month # positive 192604   506
    #> 6:     size     month # positive 192605   510

### finRes

Although the [FFresearch](https://github.com/bautheac/FFresearch/)
package is self-contained it belongs to the
[finRes](https://bautheac.github.io/finRes/) suite of packages where it
helps with asset pricing research and analysis.

## References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-fama_cross_section_1992" class="csl-entry">

Fama, Eugene F., and Kenneth R. French. 1992. “The Cross-Section of
Expected Stock Returns.” *The Journal of Finance* 47 (2): 427–65.
<https://doi.org/10.1111/j.1540-6261.1992.tb04398.x>.

</div>

<div id="ref-fama_common_1993" class="csl-entry">

———. 1993. “Common Risk Factors in the Returns on Stocks and Bonds.”
*Journal of Financial Economics* 33 (1): 3–56.
<https://doi.org/10.1016/0304-405X(93)90023-5>.

</div>

<div id="ref-fama_size_1995" class="csl-entry">

———. 1995. “Size and Book-to-Market Factors in Earnings and Returns.”
*The Journal of Finance* 50 (1): 131–55.
<https://doi.org/10.1111/j.1540-6261.1995.tb05169.x>.

</div>

<div id="ref-fama_industry_1997" class="csl-entry">

———. 1997. “Industry Costs of Equity.” *Journal of Financial Economics*
43 (2): 153–93. <https://doi.org/10.1016/S0304-405X(96)00896-3>.

</div>

<div id="ref-fama_five_factor_2015" class="csl-entry">

———. 2015. “A Five-Factor Asset Pricing Model.” *Journal of Financial
Economics* 116 (1): 1–22.
<https://doi.org/10.1016/j.jfineco.2014.10.010>.

</div>

<div id="ref-fama_dissecting_2016" class="csl-entry">

———. 2016. “Dissecting Anomalies with a Five-Factor Model.” *The Review
of Financial Studies* 29 (1): 69–103.
<https://doi.org/10.1093/rfs/hhv043>.

</div>

<div id="ref-fama_international_2017" class="csl-entry">

———. 2017. “International Tests of a Five-Factor Asset Pricing Model.”
*Journal of Financial Economics* 123 (3): 441–63.
<https://doi.org/10.1016/j.jfineco.2016.11.004>.

</div>

</div>
