package test;

import org.simplepools.smartcontract.SimplePools;

import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Parameter;
import java.util.ArrayList;

public class MainTest {
   public static void main(String[] args) {
      ArrayList POOL_STRING_FIELD_NAMES = new ArrayList();
      ArrayList POOL_STRING_FIELD_TYPES = new ArrayList();
      ArrayList POOL_FIELD_TYPES = new ArrayList();
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
         System.out.println();
      } catch (Exception e) {
         e.printStackTrace();
      }
   }
}
