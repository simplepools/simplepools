package data;

import java.math.BigInteger;
import java.util.HashMap;
import java.util.Map;

public class DataUtil {


   static Map<Class<?>, String> typeMappingJavaToDb = new HashMap<>();
   static {
      String stringType = "string";
      String intType = "string";
      typeMappingJavaToDb.put(BigInteger.class.getClass(), stringType);
      typeMappingJavaToDb.put(Boolean.class.getClass(), stringType);
      typeMappingJavaToDb.put(String.class.getClass(), stringType);
      typeMappingJavaToDb.put(Long.class.getClass(), intType);
   }
}
