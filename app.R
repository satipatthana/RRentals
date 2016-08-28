library(shiny)
library(FinCal)
library(plotly)


ui<-fluidPage(
  tabsetPanel(
    tabPanel("R for Rentals",
      fluidRow(column(5,offset=5,h4("Home Rental Cash Flows"))),
      fluidRow(
      column(3,
      wellPanel(h4("PURCHASE"),
      numericInput("homeprice", "Home Price ($)",250000,100000,2000000,10000),
      numericInput("down","Down Payment (%)",20,min=0,max=100),
      numericInput("int","Interest Rate (%)",3.5,1,10,0.125),
      numericInput("term","Loan Term (years)",30,15,30,15))
      ),
      column(6,
        wellPanel(fluidRow(h4("RENTAL OPERATION")),
        fluidRow(
          column(6,
               numericInput("rent", "Rent ($/month), Starting",1700,100,10000,50),
               numericInput("vac","Vacancy Buffer (%/year)",5,0,100,1),
               numericInput("rentesc","Rental Escalation (%/year)",1,0,20,0.5),
               numericInput("hoa","HOA ($/month)",100,0,2000,25)
               ),
         column(6,
               numericInput("ins","Insurance and Other Expenses ($/month)",100,0,2000,25),
               numericInput("mgmt","Management Fee ($/month)",100,0,1000,25),
               numericInput("opexesc","Operating Expense Escalation (%/year)",2,0,20,0.5),
               numericInput("ptax","Annual Property Tax Rate (% of Home Price)",1,0,10,0.1)
              ))
      )),
      column(3,
        wellPanel(h4("SALE"),
        numericInput("saleyear","Years to own property",15,1,100,1),
        numericInput("apprate","Yearly Appreciation Rate (%)",0.5,0,20,0.1),
        h4("TAX RATES"),
        numericInput("itax","Income Tax Rate (%)",29,0,50,1),
        numericInput("ctax","Capital Gains Tax Rate (%)",20,0,50,1)
      ))),
      fluidRow(
        column(3,offset=5, actionButton("go","Click for Cash Flows"))),
      fluidRow(
        column(8,offset=1,
        h4("  Cash flows for period of ownership (sale at end of period)"),
        plotlyOutput("ncfplot"),
        h4("  Internal rate of return of cash flows (%)"),
        verbatimTextOutput("irr")
        )
      )
    ),
    tabPanel("Description",
             fluidRow(
                      h5("This web application created in Shiny calculates cash flows, and a rate of return based on user specified inputs.  Defaut values are provided, and the user can adjust values as desired.  User inputs can be specified for different stages of ownership - namely, the Purchase stage, the Rental Operation stage, and the Sale stage.  In addition, tax rates can be specified.  After entering the data, pressing the Click for Cash Flows button will provide (a) a graphical depiction of annual cash flows for the period covering purchase to sale (hovering over the bars shows the actual value of the cash flow for the year), and (b) an Internal Rate of Return for the series of cash flows over the period.")
             )
    )))


server<-function(input,output){
  output$prin<-renderPrint({input$homeprice*(1-input$down/100)})
# Calculate Amortization Table.  Used n later calculation for annual mortgage interest payments,
# and loan balance calculations
  atab<-eventReactive(input$go,{
    p<-input$homeprice*(1-input$down/100)
    r<-input$int/(12*100)
    n<-12*input$term
    pmt<-p*(r/(1-(1+r)^-n))
    atab<-data.frame("period"=1:n,"pmt"=pmt,"begbal"=0,"mint"=0,"ppay"=0,"endbal"=0)
    for (i in 1:n){
      atab[i,3]=p
      atab[i,4]<-atab[i,3]*r
      atab[i,5]<-atab[i,2]-atab[i,4]
      p=p-atab[i,5]
      atab[i,6]=p
      next
    }
    atab$pctequity<-atab$ppay/atab$pmt*100
    atab$pctint<-atab$mint/atab$pmt*100
    atab
  })
# Calculate cash flows
  cf<-eventReactive(input$go,{
    cf<-data.frame("term"=0:input$saleyear,"ii"=0,"ri"=0,"mp"=12*atab()$pmt[1],"oe"=0,"ret"=(input$homeprice)*(input$ptax/100),"ibt"=0,"apalg"=0,"it"=0,"palr"=0,"ncs"=0,"ncf"=0)
    cf[1,2]<--(input$down+1)/100*input$homeprice
    cf[1,4]=0
    cf[1,6]=0
    cf[2,3]<-12*input$rent*(1-input$vac/100)
    cf[2,5]<-12*(input$hoa+input$ins+input$mgmt)
    if(input$saleyear>input$term){
      cf$mp[(input$term+2):(input$saleyear+1)]<-0
    }
    for (i in 3:(input$saleyear+1)){
      cf[i,3]<-cf[i-1,3]*(1+input$rentesc/100)
      cf[i,5]<-cf[i-1,5]*(1+input$opexesc/100)
      next
    }
    for(i in 2:(input$saleyear+1)){
      if (i<input$term){
        cf[i,7]<-cf[i,3]-cf[i,5]-cf[i,6]-sum(atab()$mint[((i-2)*12+1):((i-2)*12+12)])
      } else {
        cf[i,7]<-cf[i,3]-cf[i,5]-cf[i,6]
      }
  
      if (i<29) {
        cf[i,7]<-cf[i,7]-1.01*input$homeprice/27.5
      } 
      cf[i,8]<-cf[i-1,8]+cf[i,7]
      if (cf[i,8]>0){
        cf[i,9]<-cf[i,7]*input$itax/100
      } 
      next
    }
    if (cf[input$saleyear+1,8]<0){
      cf[input$saleyear+1,10]<--cf[input$saleyear+1,8]*input$itax/100
    }
    sp<-input$homeprice*(1+input$apprate/100)^input$saleyear
    cc<-sp*6/100
    if (input$saleyear<27){
      basis<-input$homeprice-input$saleyear*1.01*input$homeprice/27.5
    }else{
      basis<-0
    }
    capgaintax<-(input$ctax/100)*(sp-cc-basis)
    cashaftertaxcc<-sp-cc-capgaintax
    if (input$saleyear>=input$term){
      mb2bank<-0
      } else{
        mb2bank <- atab()$endbal[12*input$saleyear]
      }
    cf[input$saleyear+1,11]<-cashaftertaxcc-mb2bank
    for (i in 0: input$saleyear+1){
      cf[i,12]<-cf[i,2]+cf[i,3]-cf[i,4]-cf[i,5]-cf[i,6]-cf[i,9]+cf[i,10]+cf[i,11]
      cf[i,12]<-round(cf[i,12],0)
      next
    }
    cf
  })
# Calculate internal rate of return from "irr" function in FinCal package  
  output$irr<-renderText({round(irr(cf()$ncf)*100,2)})
#Create plot of cash flows using plotly
    output$ncfplot<-renderPlotly({
    xtit<-list(title="Years")
    ytit<-list(title="Cash flows")
    plot_ly(x=cf()$term,y=cf()$ncf,type="bar") %>% layout(xaxis=xtit,yaxis=ytit)
  })
}

shinyApp(ui=ui,server=server)
