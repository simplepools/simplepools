package global;

import org.simplepools.PoolMetadata;
import org.simplepools.smartcontract.SimplePools;

import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Parameter;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public class Constants {

    public static final String POOLS_TABLE_PREFIX = "Pools_";
    public static final String POOLS_METADATA_TABLE_PREFIX = "Pools_Metadata_";
    public static final String TxCounter_TABLE_PREFIX = "TxCounter_";

    public static final BigDecimal TRANSFER_FEE = new BigDecimal("0.000105");
    public static final BigDecimal WITHDRAW_TAX = TRANSFER_FEE.multiply(new BigDecimal("2"));
    public static final String BUSD_CONTRACT_ADDRESS = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";
    public static final String WBNB_CONTRACT_ADDRESS = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";

    public static final String SIMPLEPOOLS_CONTRACT_ADDRESS = "0x80004035cC793678290a7e879b77c6cBA3730008";

    public static List<String> POOL_STRING_FIELD_NAMES = new ArrayList();
    public static List<String> POOL_STRING_FIELD_TYPES = new ArrayList();
    public static List<Field> POOL_FIELD_TYPES = new ArrayList();
    public static List<String> POOL_METADATA_STRING_FIELD_NAMES = new ArrayList();
    public static List<String> POOL_METADATA_STRING_FIELD_TYPES = new ArrayList();
    public static List<Field> POOL_METADATA_FIELD_TYPES = new ArrayList();
    public static String POOL_PRIMARY_ID_FIELD_NAME = "poolId";
    static {
        try {
            Constructor constructor = SimplePools.Pool.class.getConstructors()[0];
            Parameter[] parameters = constructor.getParameters();
            Field[] fields = SimplePools.Pool.class.getFields();
            for (int i = 0; i < parameters.length; ++i) {
                Field field = fields[i];
                POOL_STRING_FIELD_NAMES.add(field.getName());
                POOL_STRING_FIELD_TYPES.add(field.getType().getName());
                POOL_FIELD_TYPES.add(SimplePools.Pool.class.getField(field.getName()));
            }

            constructor = PoolMetadata.class.getConstructors()[0];
            parameters = constructor.getParameters();
            fields = PoolMetadata.class.getFields();
            for (int i = 0; i < parameters.length; ++i) {
                Field field = fields[i];
                POOL_METADATA_STRING_FIELD_NAMES.add(field.getName());
                POOL_METADATA_STRING_FIELD_TYPES.add(field.getType().getName());
                POOL_METADATA_FIELD_TYPES.add(PoolMetadata.class.getField(field.getName()));
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
