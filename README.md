FFresearch
================

[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)

<style> body {text-align: justify} </style>

Fama/French research data conveniently packaged for consumption by R
users. The data is pulled directly from Kenneth French’s online [data
library](http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html).
Size concerns limit the data history to the last ten years; the full
time series are available from the author upon request. Install from
[github](https://github.com/bautheac/FFresearch/) with
`devtools::install_github("bautheac/FFresearch")`.

### Portfolios

#### Univariate

The ‘portfolios\_univariate’ dataset provides various feature time
series for Fama/French portfolios formed on single variable sorts.
Sorting variables include size, book-to-market, operating profitability
and investment:

    #>    region frequency         sort variable dividend weights portfolio  field
    #> 1:     US       day market capitalization        Y   value     Dec 2 return
    #> 2:     US       day market capitalization        Y   value     Dec 2 return
    #> 3:     US       day market capitalization        Y   value     Dec 2 return
    #> 4:     US       day market capitalization        Y   value     Dec 2 return
    #> 5:     US       day market capitalization        Y   value     Dec 2 return
    #> 6:     US       day market capitalization        Y   value     Dec 2 return
    #>      period value
    #> 1: 19880104  2.31
    #> 2: 19880105  2.36
    #> 3: 19880106  0.76
    #> 4: 19880107  1.05
    #> 5: 19880108 -2.47
    #> 6: 19880111 -1.12

#### Bivariate

The ‘portfolios\_bivariate’ dataset provides various feature time series
for Fama/French portfolios formed on two variable sorts. Sorting
variables include size, book-to-market, operating profitability and
investment:

    #>    region frequency       sort variable 1 sort variable 2 dividend weights
    #> 1:     US       day market capitalization     book/market        Y   value
    #> 2:     US       day market capitalization     book/market        Y   value
    #> 3:     US       day market capitalization     book/market        Y   value
    #> 4:     US       day market capitalization     book/market        Y   value
    #> 5:     US       day market capitalization     book/market        Y   value
    #> 6:     US       day market capitalization     book/market        Y   value
    #>    portfolio  field   period value
    #> 1:  BIG HiBM return 19980102 -0.30
    #> 2:  BIG HiBM return 19980102 -0.39
    #> 3:  BIG HiBM return 19980102 -0.34
    #> 4:  BIG HiBM return 19980105  0.22
    #> 5:  BIG HiBM return 19980105  0.53
    #> 6:  BIG HiBM return 19980105  0.73

#### Trivariate

The ‘portfolios\_trivariate’ dataset provides various feature time
series for Fama/French portfolios formed on three variable sorts.
Sorting variables include size, book-to-market, operating profitability
and investment:

    #>    region frequency       sort variable 1 sort variable 2
    #> 1:     US     month market capitalization     book/market
    #> 2:     US     month market capitalization     book/market
    #> 3:     US     month market capitalization     book/market
    #> 4:     US     month market capitalization     book/market
    #> 5:     US     month market capitalization     book/market
    #> 6:     US     month market capitalization     book/market
    #>            sort variable 3 dividend weights     portfolio  field period  value
    #> 1: operating profitability        Y   value BIG HiBM.HiOP return 199801 3.3429
    #> 2: operating profitability        Y   value BIG HiBM.HiOP return 199801 3.3429
    #> 3: operating profitability        Y   value BIG HiBM.HiOP return 199801 3.3429
    #> 4: operating profitability        Y   value BIG HiBM.HiOP return 199801 3.3429
    #> 5: operating profitability        Y   value BIG HiBM.HiOP return 199801 3.3429
    #> 6: operating profitability        Y   value BIG HiBM.HiOP return 199801 3.3429

#### Industries

The ‘portfolios\_industries’ dataset provides various feature time
series for Fama/French industry portfolios (Fama and French 1997):

    #>    region frequency dividend weights portfolio  field period value
    #> 1:     US     month        Y   value      Aero return 199801  1.31
    #> 2:     US     month        Y   value      Aero return 199801  1.31
    #> 3:     US     month        Y   value      Aero return 199801  1.31
    #> 4:     US     month        Y   value      Aero return 199801  1.31
    #> 5:     US     month        Y   value      Aero return 199801  1.31
    #> 6:     US     month        Y   value      Aero return 199801  1.31

### Factors

The ‘factors’ dataset provides the return (factors) and level (risk free
rate) time series for the classic Fama/French asset pricing factors as
used in their three (Fama and French 1992, 1993, 1995) and most recently
five-factor (Fama and French 2015, 2016, 2017) asset pricing models
extremely popular to the asset pricing enthusiasts:

    #>    region frequency factor period value
    #> 1:     US     month    CMA 198801  2.09
    #> 2:     US     month    CMA 198802 -0.11
    #> 3:     US     month    CMA 198803  1.91
    #> 4:     US     month    CMA 198804  1.90
    #> 5:     US     month    CMA 198805  0.38
    #> 6:     US     month    CMA 198806 -3.25

### Variables

The ‘variables’ dataset is a helper dataset that provides details,
including construction methods, for the variables used to construct the
portfolios and asset pricing factors above:

    #> # A tibble: 6 x 3
    #>   name              symbol description                                          
    #>   <chr>             <chr>  <chr>                                                
    #> 1 market capitaliz~ ME     Market equity (size) is price times shares outstandi~
    #> 2 book value        BE     Book equity is constructed from Compustat data or co~
    #> 3 book/market       ME/BE  The book-to-market ratio used to form portfolios in ~
    #> 4 operating profit~ OP     The operating profitability ratio used to form portf~
    #> 5 investment        INV    The investment ratio used to form portfolios in June~
    #> 6 earnings/price    E/P    Earnings is total earnings before extraordinary item~

### Breakpoints

The ‘breakpoints’ dataset is a helper dataset that provides the times
series for the variables breakpoints used to construct the variables
that in turn allow the construction of the portfolios and asset pricing
factors above-mentioned:

    #>    variable frequency percentile period value
    #> 1:     size     month # positive 199801  1816
    #> 2:     size     month # positive 199802  1817
    #> 3:     size     month # positive 199803  1819
    #> 4:     size     month # positive 199804  1820
    #> 5:     size     month # positive 199805  1826
    #> 6:     size     month # positive 199806  1823

## References

<div id="refs" class="references">

<div id="ref-fama_cross_section_1992">

Fama, Eugene F., and Kenneth R. French. 1992. “The Cross-Section of
Expected Stock Returns.” *The Journal of Finance* 47 (2): 427–65.
<https://doi.org/10.1111/j.1540-6261.1992.tb04398.x>.

</div>

<div id="ref-fama_common_1993">

———. 1993. “Common Risk Factors in the Returns on Stocks and Bonds.”
*Journal of Financial Economics* 33 (1): 3–56.
<https://doi.org/10.1016/0304-405X(93)90023-5>.

</div>

<div id="ref-fama_size_1995">

———. 1995. “Size and Book-to-Market Factors in Earnings and Returns.”
*The Journal of Finance* 50 (1): 131–55.
<https://doi.org/10.1111/j.1540-6261.1995.tb05169.x>.

</div>

<div id="ref-fama_industry_1997">

———. 1997. “Industry Costs of Equity.” *Journal of Financial Economics*
43 (2): 153–93. <https://doi.org/10.1016/S0304-405X(96)00896-3>.

</div>

<div id="ref-fama_five_factor_2015">

———. 2015. “A Five-Factor Asset Pricing Model.” *Journal of Financial
Economics* 116 (1): 1–22.
<https://doi.org/10.1016/j.jfineco.2014.10.010>.

</div>

<div id="ref-fama_dissecting_2016">

———. 2016. “Dissecting Anomalies with a Five-Factor Model.” *The Review
of Financial Studies* 29 (1): 69–103.
<https://doi.org/10.1093/rfs/hhv043>.

</div>

<div id="ref-fama_international_2017">

———. 2017. “International Tests of a Five-Factor Asset Pricing Model.”
*Journal of Financial Economics* 123 (3): 441–63.
<https://doi.org/10.1016/j.jfineco.2016.11.004>.

</div>

</div>
