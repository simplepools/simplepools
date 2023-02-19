package data;

import global.Constants;
import global.Locks;
import mypackage.Web3Service;
import org.simplepools.PoolMetadata;
import org.simplepools.smartcontract.IERC20;
import org.simplepools.smartcontract.SimplePools;
import org.sqlite.SQLiteDataSource;

import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.math.MathContext;
import java.math.RoundingMode;
import java.sql.*;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

public class DatabaseService {

    public static final Logger LOG = Logger.getLogger(DatabaseService.class.getName());

    public static final DatabaseService INSTANCE = new DatabaseService();
    private Connection _connection;
    public static HashMap<String, String> TOKEN_NAMES_CACHE = new HashMap<>();
    public static HashMap<String, String> TOKEN_DECIMALS_CACHE = new HashMap<>();

    private DatabaseService() {
        LOG.info("Initializing DataBase");
        try {
            Class<?> c = Class.forName("org.sqlite.JDBC");
            System.out.println(c);
        } catch (Exception e) {
            e.printStackTrace();
        }
        for (int i = 0; i < 3; ++i) {
            try {
                if (get_connection()) {
                    return;
                }
            } catch (Throwable e) {
                e.printStackTrace();
            }
        }
    }


    private boolean get_connection() {
        try {
            // create a database connection
            new SQLiteDataSource(); // needed for the side effect
            _connection = DriverManager.getConnection("jdbc:sqlite:database.db");

            for (Map.Entry entry : Blockchains.PROVIDER_FOR_BLOCKCHAIN.entrySet()) {
                String dbName = Constants.POOLS_TABLE_PREFIX + entry.getKey();
                String query = Queries.createPoolsTable(dbName);
                LOG.info("Creating table if doesn't exist with: " + query);
                Statement statement = _connection.createStatement();
                statement.setQueryTimeout(30);  // set timeout to 30 sec.
                int ups = statement.executeUpdate(query);
                System.out.println(ups);

                dbName = Constants.POOLS_METADATA_TABLE_PREFIX + entry.getKey();
                query = Queries.createPoolsMetadataTable(dbName);
                LOG.info("Creating table if doesn't exist with: " + query);
                statement = _connection.createStatement();
                statement.setQueryTimeout(30);  // set timeout to 30 sec.
                ups = statement.executeUpdate(query);
                System.out.println(ups);

                dbName = Constants.TxCounter_TABLE_PREFIX + entry.getKey();
                query = Queries.createTxCounterTable(dbName);
                LOG.info("Creating table if doesn't exist with: " + query);
                statement = _connection.createStatement();
                statement.setQueryTimeout(30);  // set timeout to 30 sec.
                ups = statement.executeUpdate(query);
                System.out.println(ups);
            }

            return true;
        } catch (SQLException e) {
            // if the error message is "out of memory",
            // it probably means no database file is found
            System.err.println(e.getMessage());
        }
        return false;
    }

    public List<SimplePools.Pool> getPools(long startIndex, long endIndex, String blockchain) {
        final String poolsTable = Constants.POOLS_TABLE_PREFIX + blockchain;
        updatePoolsInDbFromWeb3(blockchain);
        ArrayList<SimplePools.Pool> result = new ArrayList<>();
        try {
            String query = Queries.selectPoolsInRange(poolsTable);
            PreparedStatement statement = _connection.prepareStatement(query);
            statement.setLong(1, startIndex);
            statement.setLong(2, endIndex);
            ResultSet rs = statement.executeQuery();
            while (rs.next()) {
                List<String> poolFields = new ArrayList<>();
                for (String field : Constants.POOL_STRING_FIELD_NAMES) {
                    poolFields.add(rs.getString(field));
                }
                Constructor targetConstructor = SimplePools.Pool.class.getConstructors()[0];

                Object[] args = new Object[Constants.POOL_STRING_FIELD_NAMES.size()];
                for (int i = 0; i < poolFields.size(); ++i) {
                    args[i] = poolFields.get(i);
                    if (Constants.POOL_STRING_FIELD_TYPES.get(i).equals(BigInteger.class.getName())) {
                        args[i] = new BigInteger((String) args[i], 10);
                    } else if (Constants.POOL_STRING_FIELD_TYPES.get(i).equals(Boolean.class.getName())) {
                        args[i] = new Boolean((String) args[i]);
                    }
                }
                SimplePools.Pool pool = (SimplePools.Pool) targetConstructor.newInstance(args);
                result.add(pool);
            }
            return result;
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Error getting all accounts information: ", e);
        }
        return null;
    }

    public List<PoolMetadata> getPoolsMetadata(long startIndex, long endIndex, String blockchain) {
        final String poolsTable = Constants.POOLS_METADATA_TABLE_PREFIX + blockchain;

        ArrayList<PoolMetadata> result = new ArrayList<>();
        try {
            String query = Queries.selectPoolsInRange(poolsTable);
            PreparedStatement statement = _connection.prepareStatement(query);
            statement.setLong(1, startIndex);
            statement.setLong(2, endIndex);
            ResultSet rs = statement.executeQuery();
            while (rs.next()) {
                List<String> poolMetadataFields = new ArrayList<>();
                for (String field : Constants.POOL_METADATA_STRING_FIELD_NAMES) {
                    poolMetadataFields.add(rs.getString(field));
                }
                Constructor targetConstructor = PoolMetadata.class.getConstructors()[0];

                Object[] args = new Object[Constants.POOL_METADATA_STRING_FIELD_NAMES.size()];
                for (int i = 0; i < poolMetadataFields.size(); ++i) {
                    args[i] = poolMetadataFields.get(i);
                    if (Constants.POOL_METADATA_STRING_FIELD_TYPES.get(i).equals(BigInteger.class.getName())) {
                        args[i] = new BigInteger((String) args[i], 10);
                    } else if (Constants.POOL_METADATA_STRING_FIELD_TYPES.get(i).equals(Boolean.class.getName())) {
                        args[i] = new Boolean((String) args[i]);
                    }
                }
                PoolMetadata poolMetadata = (PoolMetadata) targetConstructor.newInstance(args);
                result.add(poolMetadata);
            }
            return result;
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Error getting all accounts information: ", e);
        }
        return null;
    }

    public long getNumberOfPools(String blockchain) {
        try {
            final String poolsTable = Constants.POOLS_TABLE_PREFIX + blockchain;
            String query = Queries.selectCountNumberOfRows(poolsTable);
            PreparedStatement statement = _connection.prepareStatement(query);
            ResultSet rs = statement.executeQuery();
            while (rs.next()) {
                return rs.getLong(1);
            }
            throw new RuntimeException("Invalid table.");
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public boolean addPool(SimplePools.Pool pool, String blockchain) {
        try {
            final String poolsTable = Constants.POOLS_TABLE_PREFIX + blockchain;
            String query = Queries.insertPoolInto(poolsTable);
            PreparedStatement statement = _connection.prepareStatement(query);
            statement.setLong(1, pool.poolId.longValue());
            for (int i = 1; i < Constants.POOL_STRING_FIELD_NAMES.size(); ++i) {
                statement.setString(i+1, Constants.POOL_FIELD_TYPES.get(i).get(pool).toString());
            }
            int update = statement.executeUpdate();
            System.out.println(update);
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Error adding Pool to the Database: ", e);
            return false;
        }
        return true;
    }

    public boolean addPoolMetadata(PoolMetadata poolMetadata, String blockchain) {
        try {
            final String poolsMetadataTable = Constants.POOLS_METADATA_TABLE_PREFIX + blockchain;
            String query = Queries.insertPoolMetadataInto(poolsMetadataTable);
            PreparedStatement statement = _connection.prepareStatement(query);
            statement.setLong(1, poolMetadata.poolId.longValue());
            for (int i = 1; i < Constants.POOL_METADATA_STRING_FIELD_NAMES.size(); ++i) {
                statement.setString(i+1, Constants.POOL_METADATA_FIELD_TYPES.get(i).get(poolMetadata).toString());
            }
            int update = statement.executeUpdate();
            System.out.println(update);
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Error adding Pool to the Database: ", e);
            return false;
        }
        return true;
    }

    public boolean updatePool(SimplePools.Pool pool, String blockchain) {
        try {
            final String poolsTable = Constants.POOLS_TABLE_PREFIX + blockchain;
            String query = Queries.removeFrom(poolsTable);
            PreparedStatement statement = _connection.prepareStatement(query);

            statement.setLong(1, pool.poolId.longValue());

            int update = statement.executeUpdate();

            if (!addPool(pool, blockchain)) {
                throw new Exception("Pool not updated");
            }

            return true;
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Error updating Pool in the Database: ", e);
        }
        return false;
    }

    public boolean updatePoolMetadata(PoolMetadata poolMetadata, String blockchain) {
        try {
            final String poolsTable = Constants.POOLS_METADATA_TABLE_PREFIX + blockchain;
            String query = Queries.removeFrom(poolsTable);
            PreparedStatement statement = _connection.prepareStatement(query);

            statement.setLong(1, poolMetadata.poolId.longValue());

            int update = statement.executeUpdate();

            if (!addPoolMetadata(poolMetadata, blockchain)) {
                throw new Exception("Pool not updated");
            }

            return true;
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Error updating Pool in the Database: ", e);
        }
        return false;
    }

    public void closeSqlConnection() {
        try {
            if (_connection != null) {
                _connection.close();
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Error closing SQL connection: ", e);
            // connection close failed.
        }
    }

    private volatile static long lastCheck = 0;
    private static Object lastCheckLock = new Object();

    long getCounter(String blockchain) {
        try {
            final String COUNTER_TABLE = Constants.TxCounter_TABLE_PREFIX + blockchain;
            String query = Queries.selectCounter(COUNTER_TABLE);
            PreparedStatement statement = _connection.prepareStatement(query);
            statement.setString(1, Constants.SIMPLEPOOLS_CONTRACT_ADDRESS);
            ResultSet rs = statement.executeQuery();

            while (rs.next()) {
                if (rs.getString("contract_address").equals(Constants.SIMPLEPOOLS_CONTRACT_ADDRESS)) {
                    return Long.parseLong(rs.getString("count"));
                }
            }
            // Counter is not found, add it.
            query = Queries.insertIntoTxCounter(COUNTER_TABLE);
            statement = _connection.prepareStatement(query);
            statement.setString(1, Constants.SIMPLEPOOLS_CONTRACT_ADDRESS);
            statement.setLong(2, 0);
            int update = statement.executeUpdate();
            return 0;
        } catch (Exception e) {
            // error
            e.printStackTrace();
        }
        throw new RuntimeException("cannot get counter from db");
    }

    public void updatePoolsInDbFromWeb3(String blockchain) {
        try {
            synchronized (lastCheckLock) {
                long currentTime = System.currentTimeMillis();
                // Do not spam web3 with queries
                if (currentTime - lastCheck < TimeUnit.SECONDS.toMillis(30)) {
                    return;
                }
                lastCheck = currentTime;
            }

            long currentCounter = getCounter(blockchain);

            Web3Service web3Service = Web3Service.INSTANCE;
            SimplePools simplePools = web3Service.getSimplePools(blockchain);
            BigInteger txs = simplePools.getTransactionsCount().send();

            if (currentCounter != txs.longValue()) {
                // update pools
                Set<BigInteger> poolsIds = new HashSet<>();
                long queryElements = 100;
                for (long i = currentCounter; i < txs.longValue(); i += queryElements) {
                    List<BigInteger> poolIdsToUpdate = simplePools
                          .getPoolsForTransactionsWithIndexesBetween(
                                BigInteger.valueOf(i),
                                BigInteger.valueOf(Math.min(i + queryElements, txs.longValue()))
                          ).send();

                    for (BigInteger poolId : poolIdsToUpdate) {
                        poolsIds.add(poolId);
                    }
                }

                ArrayList<BigInteger> poolsToFetch = new ArrayList<>(poolsIds);
                for (int i = 0; i < poolsToFetch.size(); i += queryElements) {
                    List<SimplePools.Pool> pools = simplePools
                          .getPools(poolsToFetch.subList(i,
                                Math.min(i + (int)queryElements, poolsToFetch.size()))).send();
                    for (SimplePools.Pool pool : pools) {
                        updatePool(pool, blockchain);


                        String token1Name;
                        if (pool.isAsset1NativeBlockchainCurrency) {
                            token1Name = "ETH";
                        } else {
                            token1Name = TOKEN_NAMES_CACHE.get(pool.asset1);
                            if (token1Name == null) {
                                token1Name = web3Service.getIERC20(blockchain, pool.asset1).name().send();
                                TOKEN_NAMES_CACHE.put(pool.asset1, token1Name);
                            }
                        }
                        String token2Name;
                        if (pool.isAsset2NativeBlockchainCurrency) {
                            token2Name = "ETH";
                        } else {
                            token2Name = TOKEN_NAMES_CACHE.get(pool.asset2);
                            if (token2Name == null) {
                                token2Name = web3Service.getIERC20(blockchain, pool.asset2).name().send();
                                TOKEN_NAMES_CACHE.put(pool.asset2, token2Name);
                            }
                        }

                        String token1Decimals;
                        if (pool.isAsset1NativeBlockchainCurrency) {
                            token1Decimals = "18";
                        } else {
                            token1Decimals = TOKEN_DECIMALS_CACHE.get(pool.asset1);
                            if (token1Decimals == null) {
                                token1Decimals = Long.toString(web3Service.getIERC20(blockchain, pool.asset1).decimals().send().longValue());
                                TOKEN_DECIMALS_CACHE.put(pool.asset1, token1Decimals);
                            }
                        }
                        String token2Decimals;
                        if (pool.isAsset2NativeBlockchainCurrency) {
                            token2Decimals = "18";
                        } else {
                            token2Decimals = TOKEN_DECIMALS_CACHE.get(pool.asset2);
                            if (token2Decimals == null) {
                                token2Decimals = Long.toString(web3Service.getIERC20(blockchain, pool.asset2).decimals().send().longValue());
                                TOKEN_DECIMALS_CACHE.put(pool.asset2, token2Decimals);
                            }
                        }

                        BigDecimal price;
                        if (pool.asset1Amount.equals(BigInteger.ZERO)) {
                            price = BigDecimal.ZERO;
                        } else {
                            BigDecimal tok2RealPlusVirtualDec = new BigDecimal(pool.asset2Amount.add(pool.asset2InitiallyAskedAmount))
                                  .divide(BigDecimal.valueOf(Math.pow(10, Integer.valueOf(token2Decimals))), MathContext.DECIMAL128);
                            BigDecimal tok1AmountDec = new BigDecimal(pool.asset1Amount)
                                  .divide(BigDecimal.valueOf(Math.pow(10, Integer.valueOf(token1Decimals))), MathContext.DECIMAL128);
                            price = tok2RealPlusVirtualDec.divide(tok1AmountDec, MathContext.DECIMAL128);
                        }

                        PoolMetadata poolMetadata = new PoolMetadata(
                              pool.poolId,
                              token1Name,
                              token1Name,
                              token1Decimals,
                              token2Name,
                              token2Name,
                              token2Decimals,
                              price.toString()
                        );
                        updatePoolMetadata(poolMetadata, blockchain);
                    }
                }

                String updateCounterQuery = Queries.updateCounter(Constants.TxCounter_TABLE_PREFIX + blockchain);
                PreparedStatement statement = _connection.prepareStatement(updateCounterQuery);
                statement.setLong(1, txs.longValue());
                statement.setString(2, Constants.SIMPLEPOOLS_CONTRACT_ADDRESS);
                int update = statement.executeUpdate();
                System.out.println(update);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
