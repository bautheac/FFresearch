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
Installing from source needs several GB of RAM: `portfolios_bivariate`
alone is about 28.6 million rows (~1.9 GB serialized), and the standard
installation’s lazy-load step needs close to 3 GB. See
[docs/verification-spec-3.md](docs/verification-spec-3.md) for the
measured peaks and memory-safe installation scripts.

### Portfolios

#### Univariate

The `portfolios_univariate` dataset provides various feature time series
for Fama/French portfolios formed on single variable sorts. Sorting
variables include size, book-to-market, operating profitability and
investment. Series run from 1971 through September 2026:

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
    #> 1: 19710104 -0.31
    #> 2: 19710105  1.64
    #> 3: 19710106  1.34
    #> 4: 19710107  0.12
    #> 5: 19710108 -0.18
    #> 6: 19710111  0.45

#### Bivariate

The `portfolios_bivariate` dataset provides various feature time series
for Fama/French portfolios formed on two variable sorts. Sorting
variables include size, book-to-market, operating profitability and
investment. Coverage starts in 1971 for the US sorts and July 1990 for
the regional sorts (developed, developed (ex US), Europe, JP,
Asia-Pacific (ex JP) and North America), through September 2026. The
1971 start is a maintainer decision (2026-11-14): R’s lazy-load database
cannot serialize objects larger than 2^31 − 1 bytes, and the
full-history bivariate (34.8 million rows) exceeded that limit, breaking
standard installation on every platform. The portfolio series and
breakpoints are therefore trimmed to 1971; the decision was extended to
`factors` the same day (`variables` has no periods). See
[docs/verification-spec-3.md](docs/verification-spec-3.md).

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
    #> 1:  BIG HiBM return 19710104 -1.59
    #> 2:  BIG HiBM return 19710105 -0.05
    #> 3:  BIG HiBM return 19710106  0.53
    #> 4:  BIG HiBM return 19710107 -0.05
    #> 5:  BIG HiBM return 19710108  0.14
    #> 6:  BIG HiBM return 19710111  0.31

#### Trivariate

The `portfolios_trivariate` dataset provides various feature time series
for Fama/French portfolios formed on three variable sorts. Sorting
variables include size, book-to-market, operating profitability and
investment. Series run from 1971 (US) and July 1990 (regional) through
September 2026:

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
    #> 1: operating profitability        Y   value BIG HiBM.HiOP return 197101 18.7986
    #> 2: operating profitability        Y   value BIG HiBM.HiOP return 197102  4.1366
    #> 3: operating profitability        Y   value BIG HiBM.HiOP return 197103  0.6218
    #> 4: operating profitability        Y   value BIG HiBM.HiOP return 197104  0.9330
    #> 5: operating profitability        Y   value BIG HiBM.HiOP return 197105  2.6881
    #> 6: operating profitability        Y   value BIG HiBM.HiOP return 197106  0.7564

#### Industries

The `portfolios_industries` dataset provides various feature time series
for Fama/French industry portfolios (Fama and French 1997). Series run
from 1971 through September 2026:

    #>    region frequency dividend weights portfolio  field period value
    #>    <fctr>    <fctr>   <fctr>  <fctr>    <char> <fctr> <char> <num>
    #> 1:     US     month        Y   value      Aero return 197101 22.26
    #> 2:     US     month        Y   value      Aero return 197102  4.05
    #> 3:     US     month        Y   value      Aero return 197103  2.51
    #> 4:     US     month        Y   value      Aero return 197104  6.51
    #> 5:     US     month        Y   value      Aero return 197105 -4.10
    #> 6:     US     month        Y   value      Aero return 197106 -1.97

### Factors

The `factors` dataset provides the return (factors) and level (risk free
rate) time series for the classic Fama/French asset pricing factors as
used in their three (Fama and French 1992, 1993, 1995) and most recently
five-factor (Fama and French 2015, 2016, 2017) asset pricing models
extremely popular to the asset pricing enthusiasts. Series run from 1971
(US) and July 1990 (regional) through September 2026:

    #>    region frequency factor period value
    #>    <fctr>    <fctr> <char> <char> <num>
    #> 1:     US     month    CMA 197101 -0.05
    #> 2:     US     month    CMA 197102 -0.78
    #> 3:     US     month    CMA 197103 -2.67
    #> 4:     US     month    CMA 197104  0.84
    #> 5:     US     month    CMA 197105  0.21
    #> 6:     US     month    CMA 197106 -1.69

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
factors abovementioned. Breakpoints run from 1971 through September
2026:

    #>    variable frequency percentile period value
    #>      <fctr>    <fctr>     <fctr> <char> <num>
    #> 1:     size     month # positive 197101  1274
    #> 2:     size     month # positive 197102  1275
    #> 3:     size     month # positive 197103  1277
    #> 4:     size     month # positive 197104  1279
    #> 5:     size     month # positive 197105  1287
    #> 6:     size     month # positive 197106  1288

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
