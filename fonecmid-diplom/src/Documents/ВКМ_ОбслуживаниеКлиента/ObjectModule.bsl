#Область ОбработчикиСобытий

Процедура ОбработкаПроверкиЗаполнения(Отказ, ПроверяемыеРеквизиты)
	
	ЗначенияРеквизитовДоговора = ОбщегоНазначения.ЗначенияРеквизитовОбъекта(Договор, "ВидДоговора,ВКМ_ДатаНачалаДоговора,ВКМ_ДатаОкончанияДоговора");
	
	Если ЗначенияРеквизитовДоговора.ВидДоговора <> Перечисления.ВидыДоговоровКонтрагентов.ВКМ_АбонентскаяПлата Тогда
		ОбщегоНазначения.СообщитьПользователю("Вид договора должен быть Абонентская плата");
		Отказ = Истина;
	КонецЕсли;
	
	Если ДатаПроведенияРабот < ЗначенияРеквизитовДоговора.ВКМ_ДатаНачалаДоговора Или ДатаПроведенияРабот > ЗначенияРеквизитовДоговора.ВКМ_ДатаОкончанияДоговора Тогда
		ОбщегоНазначения.СообщитьПользователю("Дата проведения работ не соответствует датам действия договора");
		Отказ = Истина;
	КонецЕсли;
	
КонецПроцедуры

Процедура ОбработкаПроведения(Отказ, РежимПроведения)
			
	ЗначениеЧасовойСтавки = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Договор, "ВКМ_ЧасоваяСтавка");
	
	Движения.ВКМ_ВыполненныеКлиентуРаботы.Записывать = Истина;
	Движения.Записать();
	
	Движения.ВКМ_ВыполненныеКлиентуРаботы.Записывать = Истина;
	
	Движение = Движения.ВКМ_ВыполненныеКлиентуРаботы.ДобавитьПриход();
	Движение.Период = ДатаПроведенияРабот;
	Движение.Клиент = Клиент;
	Движение.Договор = Договор;
	Движение.КоличествоЧасов = ВыполненныеРаботы.Итог("ЧасыКОплатеКлиенту");
	Движение.СуммаКОплате = ЗначениеЧасовойСтавки * ВыполненныеРаботы.Итог("ЧасыКОплатеКлиенту");
	
КонецПроцедуры

Процедура ПередЗаписью(Отказ, РежимЗаписи, РежимПроведения)
	
	ВсегоФактическихчасов = ВыполненныеРаботы.Итог("ФактическиПотраченоЧасов");
    ВсегоЧасовКОплате = ВыполненныеРаботы.Итог("ЧасыКОплатеКлиенту"); 
	
	СправочникОбъект = Справочники.ВКМ_Уведомления.СоздатьЭлемент();
	
	Если ЭтоНовый() Тогда			
		Текст = СтрШаблон("Во вновь добавленном документе от даты: %1, фактически потрачено часов %2, часов к оплате клиенту: %3, специалист %4",
							Дата, ВсегоФактическихчасов, ВсегоЧасовКОплате, Специалист);	
		СправочникОбъект.Текст = Текст;		
	Иначе	
		Запрос = Новый Запрос;
		Запрос.Текст = "ВЫБРАТЬ
		               |	СУММА(ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.ФактическиПотраченоЧасов) КАК ФактическиПотраченоЧасов,
		               |	СУММА(ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.ЧасыКОплатеКлиенту) КАК ЧасыКОплатеКлиенту,
		               |	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.Ссылка.Договор КАК Договор,
		               |	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.Ссылка.Специалист КАК Специалист,
		               |	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.Ссылка.Дата КАК Дата
		               |ИЗ
		               |	Документ.ВКМ_ОбслуживаниеКлиента.ВыполненныеРаботы КАК ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы
		               |ГДЕ
		               |	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.Ссылка = &Ссылка
		               |
		               |СГРУППИРОВАТЬ ПО
		               |	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.Ссылка.Договор,
		               |	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.Ссылка.Специалист,
		               |	ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.Ссылка.Дата"; 
		
		Запрос.УстановитьПараметр("Ссылка",Ссылка);
		Выборка = Запрос.Выполнить().Выбрать(); 
		
		МассивФрагментов = Новый Массив;
	
		Пока Выборка.Следующий() Цикл
		
			Если Выборка.ФактическиПотраченоЧасов <> ВсегоФактическихчасов Тогда
				МассивФрагментов.Добавить("Всего фактически потрачено часов: " + Строка(ВсегоФактическихчасов));	
			КонецЕсли;
			
			Если Выборка.ЧасыКОплатеКлиенту <> ВсегоЧасовКОплате Тогда
				МассивФрагментов.Добавить("Всего часов клиенту к оплате: " + Строка(ВсегоЧасовКОплате));		
			КонецЕсли; 
			
			Если Выборка.Специалист <> Специалист Тогда
				МассивФрагментов.Добавить("Специалист по заявке: " + Строка(Специалист));		
			КонецЕсли;
		
		КонецЦикла;
		
		ТекстОбновленногоДокумента = СтрСоединить(МассивФрагментов, ", ");
		СправочникОбъект.Текст = ТекстОбновленногоДокумента;

	КонецЕсли;
	
	СправочникОбъект.Записать();	
	
КонецПроцедуры

#КонецОбласти
