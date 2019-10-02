using System;
using System.Threading;
using System.Globalization;
namespace Hello {
  public static class Program {
    public static void Main() {
      Console.WriteLine("The current culture is {0}.", CultureInfo.CurrentUICulture.Name);
      Console.WriteLine("Message: {0}", Strings.Hello);

      // Change the current culture to fr-CA.
      Thread.CurrentThread.CurrentUICulture = CultureInfo.GetCultureInfo("fr-CA");

      Console.WriteLine("The current culture is {0}.", CultureInfo.CurrentUICulture.Name);
      Console.WriteLine("Message: {0}", Strings.Hello);
    }
  }
}
