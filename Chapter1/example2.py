from itoolkit import *
from itoolkit.transport import DirectTransport
itransport = DirectTransport()

itool = iToolKit()

itool.add(iCmd('addlible', 'addlible rthompson1'))

itool.add( 
          iPgm('rpgle_results','EXAMPLE2')
          .addParm(iData('InParm','500000a','IBMi', {'varying': 4}))
          .addParm(iData('OutParm','500000a',' ', {'varying': 4})) 
         )
         
itool.call(itransport)

# results are returned as a dictionary formatted as Json

rpgle_results = itool.dict_out('rpgle_results')

if 'success' in rpgle_results:
    print(rpgle_results)
else:
    print('Errors occurred.')
    
# parse the Json response from the dictionary
print('\n')
print("OutParm: ", rpgle_results['OutParm'])
print("Status: ", rpgle_results['success'])
