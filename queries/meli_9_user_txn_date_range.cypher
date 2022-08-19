/*
 This version provides a parameterized way of chunking user-transaction range into threads
 For the given txn period (e.g. 6 months), a set of transaction date ranges are calculated
 For each user found in the first part of the query, a set of maps is constructed like:
    [
        {accountID: <user1 accountId>, txnDateRange: { 
                startDate: txnStart+0, 
                endDate: txnStart+numDaysPerThread
            }
        },
        {accountID: <user1 accountId>, txnDateRange: { 
                startDate: txnStart+numDaysPerThread, 
                endDate: txnStart+(2*numDaysPerThread)
            }
        },
        etc
    ]
For instance, for a six month period, and a numDaysPerThread=15 this would form approximately 12 entries for each user 
(will probably for 13 to handle remaining days)

Each of these entries is passed in as userDateRanges and therefore you can control the number of days per thread
*/

// set up parameters
WITH {
    date: "2021-05-01",     // was 2021-10-01
    amlCaseMonthRange: 'P2M',
    txnMonthRange: 'P6M',
    txn90Days: 'P3M',
    companySocietyType: ['ASOCIACION','COOPERADORA','FUNDACION','IGLESIAS','ENTIDADES RELIGIOSAS','IGLESIAS, ENTIDADES RELIGIOSAS','INSTITUTO DE VIDA CONSAGRADA','IGLESIA CATOLICA'],
    totalAccountFundAmt180d: 0,
    totalUsdIncomingAmt90d: 1000, // was 2000
    totalIncomingAmt180d: 6000, // was 1176000,
    numDaysPerThread: 15
} as params

// calculate date ranges
WITH params, {
    amlCaseStartDate: date.truncate('month',date(params.date) - duration(params.amlCaseMonthRange)),
    amlCaseEndDate: date.truncate('month',date(params.date)),
    txnStartDate: date.truncate('month',date(params.date) - duration(params.txnMonthRange)),
    txnEndDate: date.truncate('month',date(params.date)),
    txn90DaysDate: date.truncate('month',date(params.date) - duration(params.txn90Days))
} as dates

// calculate txn ranges for splitting into multiple threads
WITH params, apoc.map.merge(dates, {
    txnDateRanges: [x in range(0, duration.inDays(dates.txnStartDate, dates.txnEndDate).days, params.numDaysPerThread) |
        {
            startDate: date(dates.txnStartDate) + duration({days: x}),
            endDate: apoc.coll.min([date(dates.txnStartDate) + duration({days: x + params.numDaysPerThread}), dates.txnEndDate])
        }
    ]
}) as dates

// begin query
MATCH (usr:Company) -[:HAS_ACCOUNT]-> (da:DepositAccount)
WHERE usr.isInternalUser = false
AND usr.siteID = 'MLA'
AND usr.companySocietyType IN params.companySocietyType

//Remuevo aquellos usuarios que tengan casos Cerrados, que hayan sido abiertos en los 2 meses anteriores.
OPTIONAL MATCH (usr) -[:HAS_CASE]-> (c:AMLCase)
WHERE (dates.amlCaseStartDate <= c.creationDate < dates.amlCaseEndDate) and c.status = 'CLOSED'
WITH params, dates, da, count(c) as closed_cases_qty 
WHERE ( closed_cases_qty = 0 or closed_cases_qty is null)
//LIMIT 500

//Ejecuto en diferentes hilos por USERS, la busqueda de transacciones
UNWIND dates.txnDateRanges as txnDateRange
WITH params, dates, collect({accountID: da.accountID, txnDateRange: txnDateRange}) as userDateRanges

CALL apoc.cypher.mapParallel2(
"
//Busco transacciones de Incoming a sus cuentas.
WITH $dates as dates, _ as userDateRange
MATCH (da:DepositAccount)
WHERE da.accountID IN userDateRange.accountID
WITH dates, da, userDateRange
MATCH (da)<-[:CREDITS]-(txn:Transaction)    
WHERE userDateRange.txnDateRange.startDate <= txn.date < userDateRange.txnDateRange.endDate
  AND txn.siteID = 'MLA' 
  AND txn.status = 'approved'

//Calculo los montos por período
WITH dates, da,
sum((CASE WHEN txn.operationType = 'account_fund' and txn.payMethod in ['ticket','atm','bank_transfer'] THEN txn.amount ELSE 0 END)) as total_account_fund_amt_180d,
sum((CASE WHEN txn.operationType = 'account_fund' and txn.payMethod in ['ticket','atm','bank_transfer'] THEN 1 ELSE 0 END))as txn_qty_account_fund_180d,
sum((CASE WHEN txn.date >= dates.txn90DaysDate THEN txn.dolAmount ELSE 0 END)) as total_usd_incoming_amt_90d,
sum((CASE WHEN txn.date >= dates.txn90DaysDate THEN 1 ELSE 0 END)) as total_txn_qty_incoming_90d,
sum(txn.amount) as total_incoming_amt_180d,
count(1) as total_txn_qty_180d

RETURN da, total_account_fund_amt_180d, txn_qty_account_fund_180d, total_usd_incoming_amt_90d, total_txn_qty_incoming_90d, 
total_incoming_amt_180d, total_txn_qty_180d
", {dates: dates}, userDateRanges, apoc.coll.min([size(userDateRanges), 80]), 5*3600) YIELD value

WITH params, value.da as da, 
    sum(value.total_account_fund_amt_180d) as total_account_fund_amt_180d, 
    sum(value.txn_qty_account_fund_180d) as txn_qty_account_fund_180d, 
    sum(value.total_usd_incoming_amt_90d) as total_usd_incoming_amt_90d, 
    sum(value.total_txn_qty_incoming_90d) as total_txn_qty_incoming_90d, 
    sum(value.total_incoming_amt_180d) as total_incoming_amt_180d, 
    sum(value.total_txn_qty_180d) as total_txn_qty_180d

//Aplico criterio a acumulados para filtrar incoming
WHERE total_account_fund_amt_180d > params.totalAccountFundAmt180d 
  AND total_usd_incoming_amt_90d >= params.totalUsdIncomingAmt90d 
  AND total_incoming_amt_180d >= params.totalIncomingAmt180d

MATCH (ah:AccountHolder) -[:HAS_ACCOUNT]-> (da)

RETURN da.accountID as user_id,
    ah.companySocietyType as company_type, 
    total_account_fund_amt_180d,
    total_incoming_amt_180d,
    total_usd_incoming_amt_90d,
    txn_qty_account_fund_180d,
    total_txn_qty_180d,
    total_txn_qty_incoming_90d, 
    params.totalAccountFundAmt180d as total_account_fund_amt_180d_threshold, 
    params.totalUsdIncomingAmt90d as total_usd_incoming_amt_90d_threshold,
    params.totalIncomingAmt180d as total_incoming_amt_180d_threshold
