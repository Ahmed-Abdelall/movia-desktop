import 'package:flutter/widgets.dart';

class S {
  S(this.locale);
  final Locale locale;
  bool get ar => locale.languageCode == 'ar';
  String t(String key) => (_values[key] ?? const ['', ''])[ar ? 1 : 0];
  static const _values = <String, List<String>>{
    'dashboard':['Dashboard','لوحة التحكم'], 'calendar':['Calendar','التقويم'],
    'archive':['Archive','الأرشيف'], 'settings':['Settings','الإعدادات'],
    'search':['Search events','بحث في المناسبات'], 'add':['Add event','إضافة مناسبة'],
    'upcoming':['Upcoming events','المناسبات القادمة'], 'next':['Next up','المناسبة التالية'],
    'empty':['No events yet','لا توجد مناسبات بعد'], 'title':['Title','العنوان'],
    'description':['Description','الوصف'], 'date':['Date','التاريخ'], 'time':['Time','الوقت'],
    'category':['Category','التصنيف'], 'save':['Save','حفظ'], 'cancel':['Cancel','إلغاء'],
    'edit':['Edit event','تعديل المناسبة'], 'delete':['Delete','حذف'],
    'restore':['Restore','استعادة'], 'details':['Event details','تفاصيل المناسبة'],
    'appearance':['Appearance','المظهر'], 'language':['Language','اللغة'],
    'light':['Light','فاتح'], 'dark':['Dark','داكن'], 'system':['System','النظام'],
    'import':['Import JSON','استيراد JSON'], 'export':['Export JSON','تصدير JSON'],
    'data':['Data portability','نقل البيانات'], 'sort':['Sort','ترتيب'],
    'soonest':['Soonest','الأقرب'], 'latest':['Latest','الأبعد'], 'name':['Name','الاسم'],
    'days':['Days','أيام'], 'hours':['Hours','ساعات'], 'minutes':['Minutes','دقائق'],
    'seconds':['Seconds','ثوانٍ'], 'all':['All','الكل'], 'personal':['Personal','شخصي'],
    'work':['Work','عمل'], 'travel':['Travel','سفر'], 'health':['Health','صحة'],
    'other':['Other','أخرى'], 'preview':['Import preview','معاينة الاستيراد'],
    'merge':['Merge','دمج'], 'replace':['Replace all','استبدال الكل'],
    'invalid':['The file is not a valid Movia export.','الملف ليس تصديراً صالحاً من موفيا.'],
    'imported':['Import completed.','اكتمل الاستيراد.'], 'exported':['Export completed.','اكتمل التصدير.'],
    'archived':['Archived','تمت الأرشفة'], 'confirmDelete':['Delete this event permanently?','حذف هذه المناسبة نهائياً؟'],
    'events':['events','مناسبات'], 'noArchived':['No archived events','لا توجد مناسبات مؤرشفة'],
  };
}
S s(BuildContext context) => S(Localizations.localeOf(context));
