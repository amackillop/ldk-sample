Ever so often a question comes by where a forum member requests some test bitcoins to test out some functionality. Lots of times they are told they could probably test whatever they want to test using regtest instead of the test network. But it might not be clear what the regtest environment is and how to use it. So I decided to write this detailed guide to get you started from scratch.

About this guide
This guide is a write-up on how I set things up to use regtest. I'm not claiming this is the only/best way to do thing. Use it as as starting point to play around as much as you want!

Used setup
This guide was written using the following setup:

    Bitcoin Core v0.20.1
    Python 3.8.2
    bitcoinrpc library v1.0


The Basics: What is regnet?
In short regnet is a bitcoin blockchain you entirely build yourself from scratch but still adhers to all the rules of the Bitcoin network. The difficulty of the network is fixed at the lowest difficulty so you can easily mine as much blocks as you need, giving you as much bitcoins to use as you desire as a result.

You should however realize the regtest is your own private blockchain, so for instance you can't lookup transactions in your favorite blockexplorer like you can do with mainnet/testnet. In turn this also means you can mess up as much as you like and can even start all over from scratch without a problem. Regtest is a great way of fiddling around without worrying you messing things up, it really is an excellent test environment for most cases.

So if your interested if it's something you could try/use continue reading and decide yourself.

That sound promising: how to start?
All you really need is the bitcoin-core client software. The good news is if you are already running a full-node you can easily run a regtest instance alongside without it effecting your mainnet node.

You can specify settings to be used for regtest-mode only if you include a "[regtest]" section to your bitcoin.conf configuration file. I'm using Linux to write this guide so mine is in ~/.bitcoin. So either add the following lines to your bitcoin.conf file or create a new file with this content if you are starting from scratch:
Code:

[regtest]
txindex=1
server=1
rpcport=18444
rpcuser=bitcoin
rpcpassword=talk
connect=127.0.0.1:18444


Some more info on the values:
    - [regtest] statesa block with values only applicable to the regtest environment.
    - txindex=1 is not necessary but I recommend it since you will be able to get info on transactions not in your wallet if needed;
    - server=1 is set so we can communicate using the bitcoin-cli commandline tool;
    - rpcport=18444 this is the port used for regtest communication;
    - rpcuser=bitcoin this is the username used for accessing, change to whatever value you see fit;
    - rpcpassword=talk this is the password used for accessing, change to whatever value you see fit;
    - connect=127.0.0.1:18444 to ensure only local connections are allowed.

Let's get ready to rumble!
Well that wasn't to hard was it? Now fire things up:

Code:

bitcoind -regtest

At this time I think it might be good to get some feedback of bitcoind displayed. If you want you could also start bitcoind as a daemon like this:

Code:

bitcoind -daemon -regtest


This guide assumes you are comfortable using the command line interface, if you like a bit more visual aid you can instead use bitcoin-qt instead:
Code:

bitcoin-qt -regtest


Then go to the console window to enter commands:
Code:

When this guide uses a command like "bitcoin-cli -regtest blockcount" you could simply just enter the last part ("blockount") in the bitcoin-qt console window to get the same result.


Time to mine!
Ok, it's time to mine some new coins since the regtest chain is currently empty. In order to do this the "generatetoaddress" command can be used taking two parameters:

Code:

bitcoin-cli -regtest generatetoaddress <numBlocks> <address>

Where <numBlocks> is an integer value of the number of blocks we want to mine and <address> is the address the mining reward should go to.

As there is currently not an address we can use one can be created using "getnewaddress":
Code:

bitcoin-cli -regtest getnewaddress

Which will give a bech32 regtest address starting with "bcrt". If needed you can also specify to generate a legacy/p2sh-segwit address:

Code:

bitcoin-cli -regtest getnewaddress "" legacy

Or:
Code:

bitcoin-cli -regtest getnewaddress "" p2sh-segwit

Note: the "" refers to an empty label for the address. If you would use a label just put the name there, something like "Mining address".

So that brings me to addresses in regtest. Addresses on regtest are in the same format as on testnet. So if you already created addresses for testnet you can use them on regtest as well. But as always there is an exception: bech-32 addresses on testnet have a hrp (human readable part) of "tb" while on regtest the hrp is "bcrt". Just so you know.

So now that we have a regtest-address we can mine the very first block:
Code:

bitcoin-cli -regtest generatetoaddress 1 bcrt1q4gfcga7jfjmm02zpvrh4ttc5k7lmnq2re52z2y

Note: the bcrt1-address is the output I got from the getnewaddress command before.

As a result the block-hash the regtest genesis block gets returned:
Code:

[
  "0092228179de46db1fd49b59ac3e02ad6ca5ef93ac710b2fbc17831950caf821"
]


I messed up, now what?
Great! That's what regtest is all about. You created an unspendable output by making a faulty transaction? Mined a lot of coins to an address you don't have the private key to (anymore)? On testnet (and god forbid:mainnet) that would cause a problem but on regtest we can just start all over again. To do so be sure to stop running bitcoind/bitcoin-qt first. Then go to your .bitcoin directory and remove the entire regtest directory (and underlying subdirectories) to completely start over from scratch. You should be aware the regtest wallet.dat file is also in the ./bitcoin/regtest/wallets/ directory so you will delete that as well if you just nuke the entire regtest directory.

Ending of part one
This concludes the first part where we managed to setup the regtest environment, generate a new address and mine the very first block of our own private blockchain. Now there's not a lot we can do yet with our regtest environment yet so in part 2 we will dive into a few python programs to help us out.


Part Two:

In this part we are going to look into setting up the environment to get it ready for doing a transaction at the end. We could do all of this by continuing to use bitcoin-cli commands but instead we are going to do that from within Python-code. That's because I assume you want to setup the regtest environment so you can try-out some programs yourself in the long run.

Start from scratch
So let's dive right in with the python3 code used to initalize the network (I called "mini_inital.py"):
Code:

from bitcoinrpc.authproxy import AuthServiceProxy, JSONRPCException
rpc_connection = AuthServiceProxy("http://%s:%s@127.0.0.1:18444"%("bitcoin", "talk"),timeout = 120)

def get_blockchain_size():
  iBlockSize = rpc_connection.getblockcount()
  return iBlockSize

def mine_blocks(numBlocks, fullAddress):
  if numBlocks > 0 and fullAddress.strip() != '':
    rpc_connection.generatetoaddress(numBlocks, fullAddress.strip())

def get_new_wallet_address():
  fullAddress= rpc_connection.getnewaddress()
  return fullAddress

#Kick off with some network info:
regTestChainSize = get_blockchain_size()
print('The network currently consists out of %s blocks.' % regTestChainSize)
if regTestChainSize < 100:
  print('Warning: No transactions can be performed on this chain yet since there are no mature blocks!')

#set targetChainSize to the number of blocks you want the network to be after initalizing.
targetChainSize = 150
currentChainSize = get_blockchain_size()

#make sure the network consists of the number of blocks defined in targetChainSize
if currentChainSize < targetChainSize:
  blocksNeeded = targetChainSize- currentChainSize
  print('Going to mine an extra %s blocks to reach the target chainsize of %s blocks' % (blocksNeeded,targetChainSize))
  mineAddress = get_new_wallet_address()
  print('Address used for mining reward: %s.' % mineAddress)
  mine_blocks(blocksNeeded, mineAddress)

There isn't anything you need to change in the code if you setup the regtest environment as described in part 1. Be sure the settings used in the rpc_connection for port (18444), username (bitcoin), password (talk) match yours. If needed you can set the value of targetChainSize to a different value if you want the chain to consist of more or less blocks. But keep the value > 100 for now.

Check either bitcoind or bitcoin-qt are running in regtest mode, then run the program to get an output like this:
Code:

The network currently consists out of 0 blocks.
Warning: No transactions can be performed on this chain yet since there are no mature blocks!
Going to mine an extra 150 blocks to reach the target chainsize of 150 blocks
Address used for mining reward: bcrt1qkcvk53y8qfckuwemp7w9hahszk6j5eeqjae9t4.


Now the most important thing to realize is that the mining rewards for a block need to be mature, 100 confirmations needed, before they can be spent. So whenever you set up a chain consisting of less than 101 blocks you will not be able to do any transactions at all since there are no coins available to move around.
The output mentions an address used for the mining reward, this address is used for payout in all the mined blocks. You could  change that if you want, but that's how I currently set it up. The address itself will be different when you run the program. And finally: the address is available in your regtest wallet after running the program.

So there you have it: a whooping 2500 BTC (50 mature blocks, each with a mining reward of 50 BTC) to play with. You can go play around a bit, try making a transaction from within bitcoin-qt for now:



Confirmation needed
So whenever you do one or more transactions in your regtest environment they will be unconfirmed as long as you don't mine at least an extra block. Since there are no active miners on your private regtest chain you have to take care of that yourself. The good news is that means you also don't have to wait for an average of 10 minutes for a block to get mined.

Whenever you want to mine another block you could run the following program (I called "mini_extra.py"):
Code:

from bitcoinrpc.authproxy import AuthServiceProxy, JSONRPCException
rpc_connection = AuthServiceProxy("http://%s:%s@127.0.0.1:18444"%("bitcoin", "talk"),timeout = 120)

def get_blockchain_size():
  iBlockSize = rpc_connection.getblockcount()
  return iBlockSize

def mine_blocks(numBlocks, fullAddress):
  if numBlocks > 0 and fullAddress.strip() != '':
    rpc_connection.generatetoaddress(numBlocks, fullAddress.strip())

def get_new_wallet_address():
  fullAddress= rpc_connection.getnewaddress()
  return fullAddress

#=============
blocks_to_mine   = 1

#Either use a fixed address:
mineAddress = 'bcrt1qkcvk53y8qfckuwemp7w9hahszk6j5eeqjae9t4'
#Or mine extra blocks to a newaddress:
#mineAddress = get_new_wallet_address()

mine_blocks(blocks_to_mine, mineAddress)
print('A total of %s block(s) have been mined, coinbase reward to address %s' % (blocks_to_mine, mineAddress))
regTestChainSize = get_blockchain_size()
print('The network currently consists out of %s blocks.' % regTestChainSize)

Please note: Either set a fixed value in mineAddres (in the above code I set it fixed to the same value as the payout address from before) or comment the line for setting the fixed value and uncomment the line where mineAddress gets the value of a new wallet address. In the last case the extra block will be mined to a new address, which will be available in your wallet but still needs to be matured before it van be used.

When running the program an extra block will be mined. If you want multiple blocks to be mined either run the program a few times in succession or change the value of blocks_to_mine to a value > 1.
Output:
Code:

A total of 1 block(s) have been mined, coinbase reward to address bcrt1qkcvk53y8qfckuwemp7w9hahszk6j5eeqjae9t4
The network currently consists out of 151 blocks.

If you would go check the transaction in bitcoin-qt you would see it now has 1 confirmation.

Ending of part two
This concludes the second part where we build a full regtest environment, managed to do a transaction and get it confirmed. In part three we are going to build a raw transaction ourselves.


Part Three:

If you followed part one and two you find yourself with a fully setup regtest environment. You now have anything in place to experiment with whatever crazy idea you come up with. I'm going to keep it straightforward by creating a raw transaction, siging the transaction and finally sending it all from within a python program.

Let's go program stuff
'm going to keep it straightforward by creating a simple python3 script that creates a raw transaction, signing the transaction and finally sending it all from within a python program:

Code:

from bitcoinrpc.authproxy import AuthServiceProxy, JSONRPCException
import sys

rpc_connection = AuthServiceProxy("http://%s:%s@127.0.0.1:18444"%("bitcoin", "talk"),timeout = 120)

def addreses_to_spent_from():
  lstSpendableAddresses = []
  allAddresses = rpc_connection.listaddressgroupings()

  for i in range(0, len(allAddresses)):
    availableBTC = float(allAddresses[i][0][1])
    if availableBTC > 1:
      print('Suitable address found: %s' % allAddresses[i][0][0])
      lstSpendableAddresses.append(allAddresses[i][0][0])

  return lstSpendableAddresses

def make_transaction(txid, idx, address, amount):
  raw = rpc_connection.createrawtransaction(
            [{"txid": txid,
              "vout": idx}],
            {address:amount} )

  signed = rpc_connection.signrawtransactionwithwallet(raw)
  send_result = rpc_connection.sendrawtransaction(signed['hex'])

  return send_result

#=============
txid = None
for address in addreses_to_spent_from():
  unspents = rpc_connection.listunspent(1, 99999999, [address])
  num_unspents = len(unspents)
  for spendable_input in unspents:
    txid = spendable_input['txid']
    idx  = spendable_input['vout']
    amount =  float(spendable_input['amount'])
    if amount > 1:
      break;

if txid == None:
  sys.exit('No suitable input could be found for a transaction!')

trans_amount = float(amount) - (0.00000100)
trans_amount = "{:.8f}".format(trans_amount)

non_wallet_address = 'mpXwg4jMtRhuSpVq4xS3HFHmCmWp9NyGKt'
success_txid = make_transaction(txid, idx, non_wallet_address, trans_amount)
print('Transaction-id: %s' % success_txid)


The program looks for a suitable wallet address that has at least 1 unspent BTC. The first one that's found is used for obtaining the input for our transaction. The entire input is spent minus fees (set to a fixed value of 0.00000100 in this example)). The function "make_transaction" takes care of the signing and sending of the transaction and it returns the txid on success). Once again: this is meant as an example of how you can use the regtest environment yourself to programmatically experiment/test. I'm sure you can think of lots of things that are buggy in my example code, that's ok Smiley It's all about the concept of regtest not my poor programming skills!

When running the code you should get something like this in return:
Code:

Suitable address found: bcrt1qkcvk53y8qfckuwemp7w9hahszk6j5eeqjae9t4
Transaction-id: c784407fed108736c9a71d9ab2eb22ce1bf46c1ec9006d75e8a28671af86d1ae

And there you go, you just transferred 50 BTC (minus fees) to an address that's not yours or in your wallet. And if you come to regret your action, just start over your environment and start all over again.

As long as you don't mine another block the transaction you just did will stay in the mempool. So be sure to mineat least an extra block to get it confirmed and in your chain.

Ending of part three
So that concludes part 3 where we looked into making a transaction programmatically. The program itself was not to complicated but now that you know the way, knock yourself out! Maybe you want to build your own simple wallet to experiment? Go ahead! Always wanted to try how to set a higher fee for an RBF-enabled transaction? Now you can find out! Well you get the drift, you come up with an idea regtest might be the best environment to start chasing it!

Part 4: Some additional help

Diving in the internals of the regtest chain
One big difference between regtest and testnet/mainnet is you don't have a fancy blockexplorer to use. But that doesn't mean you sometimes need to check or confirm things on the regtest chain. So in order to do just that I use yet another python3 program to get some basic info on the regtest chain and transactions.

Here's the python3 program I used to create a transaction (conveniently named "info.py"):
Code:

from bitcoinrpc.authproxy import AuthServiceProxy, JSONRPCException
import sys, simplejson
rpc_connection = AuthServiceProxy("http://%s:%s@127.0.0.1:18444"%("bitcoin", "talk"),timeout = 120)

def get_blockchain_size():
  iBlockSize = rpc_connection.getblockcount()
  return iBlockSize

def get_block_hash(height):
    blockhash = rpc_connection.getblockhash(height)
    return blockhash

def get_transactions_in_block(blockhash):
    return rpc_connection.getblock(blockhash)['tx']

def get_mempool_transactions():
    mempoolTransactions = rpc_connection.getrawmempool()
    return mempoolTransactions

def lookup_transaction(txid):
    blockfound = -1
    regTestChainSize = get_blockchain_size()
    for i in range(0, regTestChainSize+1):
        blockhash = get_block_hash(i)
        for transaction in get_transactions_in_block(blockhash):
            if transaction == txid:
                blockfound = i

    return blockfound

def lookup_mempool_transaction(txid):
    found = 0
    mempoolTransactions = get_mempool_transactions()
    if len(mempoolTransactions) > 0:
        for transaction in get_mempool_transactions():
            if transaction == txid:
                found = 1
    return found

def getraw_transaction(txid):
    return rpc_connection.getrawtransaction(txid)

def decode_transaction(raw):
    parsed = rpc_connection.decoderawtransaction(raw)
    formatted_json = simplejson.dumps(parsed, indent=4)
    #print(json.loads(parsed, indent=4, sort_keys=False))
    return formatted_json

#=============
if __name__ == "__main__":
    if len(sys.argv) == 1:
        operation = 'chain'
    else:
        operation = sys.argv[1]

    #Show info on the entire chain and mempool. This is the default operation if none is specified.
    if operation.lower() == 'chain':
        regTestChainSize = get_blockchain_size()
        print('The network currently consists out of %s blocks.' % regTestChainSize)
        if regTestChainSize < 100:
            print('Warning: No transactions can be performed on this chain yet since there are no mature blocks!')

        for i in range(0, regTestChainSize+1):
            print('---------------------------------')
            print('Block height: %s' %i)
            blockhash = get_block_hash(i)
            print('Block hash  : %s' % blockhash)
            print('Transactions:')
            for transaction in get_transactions_in_block(blockhash):
                print(transaction)
            print('---------------------------------')

        print('')
        print('Mempool transactions')
        print('---------------------------------')
        mempoolTransactions = get_mempool_transactions()
        if len(mempoolTransactions) > 0:
            for transaction in get_mempool_transactions():
                print(transaction)
        else:
            print('Mempool is empty')

    #Show info on blocks containing at least one transaction other than coinbase reward
    if operation.lower() == 'blocktrans':
        regTestChainSize = get_blockchain_size()
        print('Scanning for blocks with at least one transaction other than coinbase reward:')
        for i in range(0, regTestChainSize+1):
            blockhash = get_block_hash(i)
            transInBlock = get_transactions_in_block(blockhash)
            if len(transInBlock) > 1:
                print('---------------------------------')
                print('Block height: %s' %i)
                print('Block hash  : %s' % blockhash)
                print('Transactions:')
                for transaction in transInBlock:
                    print(transaction)
                print('---------------------------------')

    #Show info on blocks containing at least one transaction other than coinbase reward
    if operation.lower() == 'mempool':
        print('')
        print('Mempool transactions:')
        mempoolTransactions = get_mempool_transactions()
        if len(mempoolTransactions) > 0:
            for transaction in get_mempool_transactions():
                print(transaction)
        else:
            print('Mempool is empty')

    #Show info on blocks containing at least one transaction other than coinbase reward
    if operation.lower() == 'trans':
        try:
            txid = sys.argv[2]
        except:
            sys.exit('Provide txid as search value')

        print('Looking up transaction %s'  % txid)

        mempoolfound = lookup_mempool_transaction(txid)
        if mempoolfound == 1:
            print('')
            print('------------------')
            print('Transaction is in the mempool (so unconfirmed)')
            print('------------------')
        else:
            blockfound = lookup_transaction(txid)
            if blockfound > -1:
                print('')
                print('------------------')
                print('Transaction is included in block with height %s' % blockfound)
                print('------------------')
            else:
                sys.exit('Transaction was not found in any block or mempool.')

        raw_transaction = getraw_transaction(txid)
        print('------------------')
        print('Raw transaction:')
        print(raw_transaction)
        print('------------------')

        decoded_json = decode_transaction(raw_transaction)
        print('')
        print('------------------')
        print('Decoded transaction:')
        print(decoded_json)
        print('------------------')


This is the first program that you can run using using a startup parameter to do different things. I'll introduce them one by one:

Get information on blocks in the chain and the mempool
Code:

python3 info.py chain

The network currently consists out of 175 blocks.
---------------------------------
Block height: 1
Block hash  : 20e3935462a04eefca66b965d9ff6c3fc75388be010ca890ddb426110160a94d
Transactions:
36d07cbb236db866aaecc768bf514a90bf2c8ae2d3f5ec852cc72f757b741f8d
---------------------------------

<snip>


---------------------------------
Block height: 175
Block hash  : 07c82a7e5ae630408d2f4f99af3dbcaacc2328d50bbea3beb6a8f7cdf55eb8bd
Transactions:
17a4fd218d864633207deedfbb2c943cefd78f96d4df5838fc731e76a4bdb16b
b5b3646b2452775964fde010c0e20282d9cb00e5d8fb3d1a75121f8725edc844
---------------------------------

Mempool transactions
---------------------------------
817e8bfc4797657d4a0e77389d168aa1018dd087a3c93195525fe0414b65956d
6cf0d8eefbc01340d81b6704907c47da13ebeb79251b1a7a155dc57124429804


Running info with the chain argument (or since it's the default without any parameter) will give you general info on the regtest chain including all transaction id's per block and transactions in mempool (if any).
Hint: If you want this info in a text file you could just redirect it, so something like: python3 info.py chain > mychain.text

Only list blocks with user generated blocks
Code:

python3 info.py blocktrans

Scanning for blocks with at lease one transaction other than coinbase reward:
---------------------------------
Block height: 151
Block hash  : 189c05ca108ff2091cf049483ea5c52e950dc789b45c51c1feaa1db0b8d0115d
Transactions:
68a10da9c0cf52aab47a6a2eb13c9404b42aff6206834e302eb5e3e1eba2fa1a
545cbb46c3a266f7ba2d0f159b5b91d4d28e140f12ab25a7fb6607940ccd511c
c52ca060fa3ac2cbb41b8708f5664a8418518b4c9b10224ee7e60f8e9783a960
002c700a5803ed49e52b3c58494b8a13a2b6d3fbab7be3c67aac2e57e02f0f71
88386302f926dd77e7aff370ddf440321daba1892c5e470de7460668eea645bd
372c3b5dffb323c850677ab852c90308b09b25a6895ee0825fc6fa20ce1dc6cf
---------------------------------
---------------------------------
Block height: 152
Block hash  : 6886d26823dab1c57f2aa1c5de27d50648a0da961e8ac5f155500ebe1ea95cb9
Transactions:
2e6f32adedc779c1eb948d77cb870f52a010e7dae703093f65db79cde1c98efa
85479cb7cfd788e94bb4b3007871857051b5282a07a1acfc458a57f9e785d35a
44c76adea68b6dd2785b61a0e48325ffd9cca95fb3e6a24585ee617e150ed99b
c784407fed108736c9a71d9ab2eb22ce1bf46c1ec9006d75e8a28671af86d1ae
---------------------------------
---------------------------------
Block height: 153
Block hash  : 71dfd97a6aca1e4183b1579fe3333aadc21670c2cf2cef88ff3281b3b8b6e111
Transactions:
dbb52d7049c9339a81b66e90509238b51d73571ff5b296d1a62d8beafb071389
499b9284eede4f80e4e19e8f1f2db289447cf85ff90bb2b536f1c8bc66ba9a99
---------------------------------
---------------------------------
Block height: 166
Block hash  : 5ab0a67ca9d6457193f57059cd37982b6620f6da016176177822f8519351f04a
Transactions:
1523e59493e6a64981256a546060ca41c40a2d51c7985c6637704918a00fcf2f
d88cf4d784d475cda43f72262573ef4c89fdf418e0a3afff2013ed917471209f
---------------------------------
---------------------------------
Block height: 170
Block hash  : 1484a88ee17b4dbc610969af1e9f6624fabd3871ccc911f0363e3a3c113757c7
Transactions:
12a00e59825ed735c7d7f9e6429bd78f4b445fe0898118b5676e7190a6475508
9e664ee1f641212df8ee6078f3f6f68bfeb2e920902d8362c2471c9081366f73
---------------------------------
---------------------------------
Block height: 175
Block hash  : 07c82a7e5ae630408d2f4f99af3dbcaacc2328d50bbea3beb6a8f7cdf55eb8bd
Transactions:
17a4fd218d864633207deedfbb2c943cefd78f96d4df5838fc731e76a4bdb16b
b5b3646b2452775964fde010c0e20282d9cb00e5d8fb3d1a75121f8725edc844


Especially when you are experimenting with transactions you might get lost which blocks contain your own generated transactions and not only coinbase transactions. So when you use the "blocktrans" parameter you can get a list of all blocks containg more than 1 transaction.


List all transactions in mempool
Code:

python3 info.py mempool

Mempool transactions:
817e8bfc4797657d4a0e77389d168aa1018dd087a3c93195525fe0414b65956d
6cf0d8eefbc01340d81b6704907c47da13ebeb79251b1a7a155dc57124429804


Pretty straightforward, when you use the mempool argument you will get all txid's (if any) currently in the mempool.

Get detailed info on a transaction
Code:

python3 info.py trans 817e8bfc4797657d4a0e77389d168aa1018dd087a3c93195525fe0414b65956d

Looking up transaction 817e8bfc4797657d4a0e77389d168aa1018dd087a3c93195525fe0414b65956d

------------------
Transaction is in the mempool (so unconfirmed)
------------------
------------------
Raw transaction:
020000000001011431a62376437bf7228db991c2fdcdf4757750eb8fcbf8e47665841082aaac750000000000ffffffff014094052a010000001976a91462e907b15cbf27d5425399ebf6f0fb50ebb88f1888ac0247304402204d645f8fc2193fee73f835e1987f694e2761f60a6e692b88e340bdcc2c5c4962022058fedeca7be2d22028a6dbac41589bb61e70518a407b48685ec30cf2dbb52c77012102d836add3dce8aeaa481aa2843e6c317654b6cebe36c22f72641ea44a506e245700000000
------------------

------------------
Decoded transaction:
{
    "txid": "817e8bfc4797657d4a0e77389d168aa1018dd087a3c93195525fe0414b65956d",
    "hash": "22ea77afe16191bc6bba5b02e62de164a2d1c70c0eda65d8e7c055c3f38c8870",
    "version": 2,
    "size": 194,
    "vsize": 113,
    "weight": 449,
    "locktime": 0,
    "vin": [
        {
            "txid": "75acaa8210846576e4f8cb8feb507775f4cdfdc291b98d22f77b437623a63114",
            "vout": 0,
            "scriptSig": {
                "asm": "",
                "hex": ""
            },
            "txinwitness": [
                "304402204d645f8fc2193fee73f835e1987f694e2761f60a6e692b88e340bdcc2c5c4962022058fedeca7be2d22028a6dbac41589bb61e70518a407b48685ec30cf2dbb52c7701",
                "02d836add3dce8aeaa481aa2843e6c317654b6cebe36c22f72641ea44a506e2457"
            ],
            "sequence": 4294967295
        }
    ],
    "vout": [
        {
            "value": 49.99976000,
            "n": 0,
            "scriptPubKey": {
                "asm": "OP_DUP OP_HASH160 62e907b15cbf27d5425399ebf6f0fb50ebb88f18 OP_EQUALVERIFY OP_CHECKSIG",
                "hex": "76a91462e907b15cbf27d5425399ebf6f0fb50ebb88f1888ac",
                "reqSigs": 1,
                "type": "pubkeyhash",
                "addresses": [
                    "mpXwg4jMtRhuSpVq4xS3HFHmCmWp9NyGKt"
                ]
            }
        }
    ]
}
------------------


If you want detailed information on a transaction either included in a block or in the mempool you can use the argument trans alongside with the txid. If the transaction is found detailed information will be shown.

Final words
I hope this guide has given you a good impression on what regtest is and why it can come in very handy. Especially when you want to experiment with transactions, scripts, and what not this might be a much better starting place then testnet!

Hope you enjoyed this guide and let me know if you have any doubts/concerns/tips, hell maybe even compliments Smiley