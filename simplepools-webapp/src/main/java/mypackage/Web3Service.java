package mypackage;

import BUSD.Wbnb;
import data.Blockchains;
import global.Constants;
import global.Locks;
import global.OnlyoneGasProvider;
import global.WalletUtil;
import org.simplepools.smartcontract.IERC20;
import org.simplepools.smartcontract.SimplePools;
import org.web3j.crypto.Credentials;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.Web3jService;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.response.EthGetBalance;
import org.web3j.protocol.core.methods.response.TransactionReceipt;
import org.web3j.protocol.http.HttpService;
import org.web3j.tx.Transfer;
import org.web3j.utils.Convert;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.math.MathContext;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

public class Web3Service {

    private static final Logger LOG = Logger.getLogger(Web3Service.class.getName());

    public static final Web3Service INSTANCE = new Web3Service();

    private final Locks _locks = Locks.INSTANCE;

    private Map<String, Web3j> WEB3J_PER_BLOCKCHAIN;
    private Map<String, SimplePools> SIMPLE_POOLS_PER_BLOCKCHAIN;

    Credentials _master = WalletUtil.getMasterWallet();

    private Web3Service() {
        WEB3J_PER_BLOCKCHAIN = new HashMap<>();
        SIMPLE_POOLS_PER_BLOCKCHAIN = new HashMap<>();
        LOG.info("Initializing Web3J service.");
        try {

            Credentials master = WalletUtil.getMasterWallet();

            for (Map.Entry<String, String> blockchain : Blockchains.PROVIDER_FOR_BLOCKCHAIN.entrySet()) {
                Web3jService service = new HttpService(blockchain.getValue());
                Web3j web3j = Web3j.build(service);
                WEB3J_PER_BLOCKCHAIN.put(blockchain.getKey(), web3j);
                SimplePools simplePools = SimplePools.load(Constants.SIMPLEPOOLS_CONTRACT_ADDRESS,
                      web3j, master, OnlyoneGasProvider.INSTANCE);
                SIMPLE_POOLS_PER_BLOCKCHAIN.put(blockchain.getKey(), simplePools);
            }

        } catch (Throwable t) {
            LOG.log(Level.SEVERE, "Couldn't initialize Web3jService", t);
            throw t;
        }
    }

    public Wbnb getWbnb() {
        // TODO fix
        return null;
    }

    public SimplePools getSimplePools(String blockchain) {
        String rpcEndpoint = Blockchains.PROVIDER_FOR_BLOCKCHAIN.get(blockchain);
        if (rpcEndpoint == null) {
            throw new RuntimeException("Invalid blockchain: " + blockchain);
        }
        return SIMPLE_POOLS_PER_BLOCKCHAIN.get(blockchain);
    }

    public IERC20 getIERC20(String blockchain, String erc20Address) {
        Web3j web3j = getWeb3j(blockchain);
        IERC20 ierc20 = IERC20.load(erc20Address,
              web3j, _master, OnlyoneGasProvider.INSTANCE);
        return ierc20;
    }

    public Web3j getWeb3j(String blockchain) {
        String rpcEndpoint = Blockchains.PROVIDER_FOR_BLOCKCHAIN.get(blockchain);
        if (rpcEndpoint == null) {
            throw new RuntimeException("Invalid blockchain: " + blockchain);
        }
        return WEB3J_PER_BLOCKCHAIN.get(blockchain);
    }
    public String getTokenBalance() {
        throw new RuntimeException("Not implemented yet");
    }
}
