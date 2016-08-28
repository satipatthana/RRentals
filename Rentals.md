# R for Rentals - Cash Flows for Home Rentals



#### Description

This web application created in Shiny calculates Cash Flows, and and Internal rate of Return based on user specified inputs.  Defaut values are provided, and the user can adjust values as desried.  User inputs can be specified for different stages of ownership - namely, the Purchase stage, the Rental Operation stage, and the Sale stage.  In addition, tax rates can be specified.  After entering the data, pressing the "Generate Cash Flows" button will provide (a) a graphical depiction of annual cash flows for the period covering purchase to sale (hovering over the bars shows the actual value of the cash flow for the year), and (b) an Internal Rate of Return for the series of cash flows over the period.

#### Calculations

The cash flows consist of the following components (a) Initial Investment, (b) Annual Rental Income, (b) Annual Mortgage Payment, (c) Annual Operating Expenses, (d) Annual Real Estate Taxes, (e) Annual Income Tax, (f) Passive Activity Loss Recoup at end of period, and (g) Net cash from sale at end of period.  The calculations for each of these compnents are briefly described below:

###### *Initial Investment*

The initial investment is the down payment for the property.  1% is added to cover cloasing costs, to the specified down payment percentage.  This is a negative cash flow at the beginning of the period.

###### *Annual Rental Income*

This is calculated as 12 times the specified monthly income.  Adjustments are made for a use specified annual vacancy rate and a user specified rental income annual escalation rate.

###### *Annual Mortgage Payment*

The annual mortgage payment is calculated from user specified home price, down payment percentage, annual interest rate, and period of loan (user can select from 15 year fixed and 30 year fixed).

###### *Annual Operating Expenses*

Annual operating expenses are claculated from user specified Homeowners Association (HOA), Insurance, and Management Fee costs.  The user can also specify an annual escalation rate for operating expenses.

###### *Annual Real Estate Taxes*

Annual real estate taxes are calculated from a user specifed real estate tax rate (expressed as % of home price).

###### *Annual Income Tax*

Annual income tax calculations can vary widely based on individual.  It is highly recommended to consult a tax professional for this part of the calculation.  For the purporses of this application, the approach outlined in the following paragraphs was taken.

First, income before tax was calculated as : Rental Income - Operating Expenses - Mortgage Interest - Depreciation expenses (calculated as (Home price + Closing Costs)/27.5).

If the income before tax is a negative value, income tax for that year is zero.  The loss for the year is carried forward as a passive activity loss, for use in a future year that has taxable passive activity income.  Any remaining passve activity loss at the end of the period is recouped at time of sale.

If income before tax is a positive value, passive activity loss carried over from previous years is deducted.  If income before tax remains positive, the amount is taxed at the user specified income tax rate.

###### *Passive Activity Loss Recoup*


Any passive activity loss that has been carried over from previous years is recouped at time of property sale.  This is calcualted as remaining passive activity loss balance times the user specified income tax rate.

###### *Net Cash From Sale*

Net cash from sale depends on various user specified values. The sale price depends on number of years after which the property is sold, and a user specified average annual appreciation rate.  From the sale price, three values are deducted:
(a) closing costs, assumed as 6% of sale price, (b) capital gains tax.  For this calculation, the basis for the capital gains is calculated as Home Price - Depreciation (based on annual depreciation rate times year of sale), and (c) loan amount still owed to the bank.

All cash flows are added on an annual basis to calcuate the annual net cash flow.  The "irr" function from the FinCal package is used to calculate the internal rate of return for the cash flows.


