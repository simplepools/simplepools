package global;

import java.util.List;

public class StringUtils {
   public static String join(String[] strings, String joiner) {
      if (strings.length == 0) {
         return "";
      }
      StringBuilder res = new StringBuilder(strings[0]);
      for (int i = 1; i < strings.length; ++i) {
         res.append(joiner).append(strings[i]);
      }
      return res.toString();
   }

   public static String[] createArrayWithEqualStrings(String string, int numberOfElements) {
      String[] res = new String[numberOfElements];
      for (int i = 0; i < numberOfElements; ++i) {
         res[i] = string;
      }
      return res;
   }
}
