
/*
1. Hacer una función que dado un artículo y un deposito devuelva un string que
indique el estado del depósito según el artículo. Si la cantidad almacenada es
menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el
% de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”.
*/

create function ej1 (@articulo char(8), @deposito char(2))
returns varchar(40)
as
BEGIN
	declare @stock numeric(12,2), @maximo numeric(12,2) --declaro
	select  @stock = isnull(stoc_cantidad, 0), @maximo = isnull(stoc_stock_maximo, 0)  --asigna valores
	from STOCK
	where stoc_deposito = @deposito and stoc_producto = @articulo
    IF (@maximo = 0 OR @stock >= @maximo)
        RETURN 'DEPOSITO COMPLETO'
        RETURN 'OCUPACION DEL DEPOSITO ' + @deposito + ' ' + STR(@stock/@maximo*100,5,2) + '%'
END
GO

--para ejecutarla 

SELECT dbo.ej1('00000030', '00') AS EstadoDeposito

select stoc_producto, stoc_deposito from stock group by stoc_deposito, stoc_producto


/*
2. Realizar una función que dado un artículo y una fecha, retorne el stock que
existía a esa fecha
*/

/*
como lo pienso:
stock q existia en esa fecha -> saco las facturas que se hicieron en esa fecha y
los item factura y sumo la cantidad de ese producto por factura. despues se lo sumo 
al stock actual y retorno

*/


create function stockDeProductoEnFecha (@articulo char(8), @fecha smalldatetime)
returns decimal(12,2)
as
BEGIN
	declare @stockActual decimal(12,2), @stockVendido decimal(12,2)
	select @stockActual = stoc_cantidad from stock where stoc_producto = @articulo
	select @stockVendido = ISNULL(item_cantidad, 0) from Item_Factura join Factura on fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
							where fact_fecha >= @fecha
return @stockActual + @stockVendido
END
GO


SELECT dbo.stockDeProductoEnFecha('00000030', CONVERT(smalldatetime, '2010-01-23', 120)) AS stock
 

/*
3. Cree el/los objetos de base de datos necesarios para corregir la tabla empleado
en caso que sea necesario. Se sabe que debería existir un único gerente general
(debería ser el único empleado sin jefe). Si detecta que hay más de un empleado
sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por
mayor salario. Si hay más de uno se seleccionara el de mayor antigüedad en la
empresa. Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla
de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad
de empleados que había sin jefe antes de la ejecución.
*/

--mayor salario
--mas antiguedad
 
 create procedure actualizarJefe @cantidad INT OUTPUT
 as
	begin 
		select @cantidad = COUNT(*) from Empleado where empl_jefe = NULL
		
		if @cantidad > 1 
			begin
				declare @jefe numeric(6)
				select @jefe = (select top 1 empl_codigo from Empleado where empl_jefe = NULL order by empl_salario desc, empl_ingreso asc)
				update Empleado set empl_jefe = @jefe where empl_jefe = NULL and empl_codigo <> @jefe
			end
	end
go

/*
4. Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese
empleado a lo largo del último año. Se deberá retornar el código del vendedor
que más vendió (en monto) a lo largo del último año.
*/

create producere actualizarEmpleados @vendedor numeric(6) output
as
	begin
		declare empl_cursor cursor for
		select empl_codigo from Empleado, @empleado numeric(6)
		open empl_cursor
		fetch next from empl_cursor into @empleado

		while @@FETCH_STATUS = 0 
			begin
				declare @sumatoriaVendido
				select @sumatoriaVendido = dbo.sumatoria_total_vendido_ultimo_anio(@empleado)
				update Empleado set empl_comision = @sumatoriaVendido
			fetch next from empl_cursor into @empleado
			end
		select @vendedor = (select top 1 empl_codigo from Empleado order by empl_comision desc) 
	end

	close empl_cursor
	deallocate empl_cursor



create function sumatoria_total_vendido_ultimo_anio(@empleado numeric(6))
returns numeric(12,2)
as 
	begin
		declare @montoTotal numeric(12,2)
		select @montoTotal = SUM(fact_total) from Factura where fact_vendedor = @empleado and YEAR(fact_fecha) = (select top 1 YEAR(fact_fecha) from Factura order by 1 desc)
	return @montoTotal
	end

/*
5. Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:
Create table Fact_table
( anio char(4),
mes char(2),
familia char(3),
rubro char(4),
zona char(3),
cliente char(6),
producto char(8),
cantidad decimal(12,2),
monto decimal(12,2)
)
Alter table Fact_table
Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)
*/

create procedure ej5 
as insert into fact_table()
	
	begin
		create table fact_table(
		anio char(4),
		mes char(2),
		familia char(3),
		rubro char(4),
		zona char(3),
		cliente char(6),
		producto char(8),
		cantidad decimal(12,2),
		monto decimal(12,2)
		)

		Alter table Fact_table
		Add constraint primary key(anio, mes, familia, rubro, zona, cliente, producto)
	end


/*
6. Realizar un procedimiento que si en alguna factura se facturaron componentes
que conforman un combo determinado (o sea que juntos componen otro
producto de mayor nivel), en cuyo caso deberá reemplazar las filas
correspondientes a dichos productos por una sola fila con el producto que
componen con la cantidad de dicho producto que corresponda.
*/






/*
7. Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock generados por
las ventas entre esas fechas. La tabla se encuentra creada y vacía.
*/







/*
8. Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por
cantidad de sus componentes, se aclara que un producto que compone a otro,
también puede estar compuesto por otros y así sucesivamente, la tabla se debe
crear y está formada por las siguientes columnas:
*/
create procedure ej8 
as
begin
	insert into diferencias
		(codigo,
		 detalle,
		 cantidad,
		 precio_generado,
		 precio_facturado)

	select
		prod_codigo,
		prod_detalle,
		(select comp_cantidad from Composicion where comp_producto = prod_codigo)
		dbo.precioComponentesRecursivo(prod_codigo),
		item_precio
	from Producto join Item_Factura on prod_codigo = item_producto where prod_codigo in (select comp_producto from Composicion)
	and prod_precio <> dbo.precioGenerado(prod_codigo)
end

alter function precioComponentesRecursivo(@producto char(8))
returns decimal(12,2)
as
begin
	declare @precioTotal decimal(12,2)
	if (select COUNT(*) from Composicion where comp_componente = @producto) = 0
		select @precioTotal = prod_precio from producto where prod_codigo = @producto
	else
		begin
			select @precioTotal = 0
			declare @comp char(8)
			declare comp_cursor cursor for select comp_componente, comp_cantidad from Composicion where comp_producto = @producto
			open comp_cursor
			fetch next from comp_cursor into @comp, @cantCompo
			while @@FETCH_STATUS = 0
				begin
					declare @cantCompo decimal(12,2)
					select @cantCompo = comp_cantidad from Composicion where comp_componente = @comp
					select @precioTotal = @precioTotal + @cantCompo * dbo.precioComponentesRecursivo(@comp)
					fetch next from comp_cursor into @comp, @cantCompo
				end
		 end
		 close comp_cursor
		 deallocate comp_cursor
		return @precioTotal
end
go 

/*
9. Crear el/los objetos de base de datos que ante alguna modificación de un ítem de
factura de un artículo con composición realice el movimiento de sus
correspondientes componentes.
*/






/*10. Crear el/los objetos de base de datos que ante el intento de borrar un artículo
verifique que no exista stock y si es así lo borre en caso contrario que emita un
mensaje de error.
*/

create trigger intentoBorrarProducto on Producto after delete
as
begin
	--aca solo estamos controlando, si no hay eliminados no hace nada, y si hay verifica que cumpla la condicion
	if(select count(*) from deleted join STOCK on stoc_producto = prod_codigo where stoc_cantidad > 0) > 0
	begin
		ROLLBACK
		RAISERROR('hay stock de este producto')
	end
end
go

-- !! anotacion
/*
	AFTER DELETE --> si nosotros mandamos un conjunto de productos a borrar y cumplen todos la condicion menos UNO entonces no se elimina ninguno

	INSTEAD OF ---> si no tiene stock un producto borra ese producto y los que cumplen NO SE BORRAN
		
		(depende de la consigna xq si mandas a ejecutar de a una instruccion la consulta debe ser atomica)

abajo un ejemplo de instead of 
*/

---queremos borrar LOS QUE SE PUEDA---
create trigger ej10 on producto instead of delete
as
begin
	delete from producto where prod_codigo not in (select stoc_producto from deleted join STOCK on stoc_producto = prod_codigo where stoc_cantidad > 0) --lo de parentesis son los que no se pueden borrar
end
go

---otro ejemplo: quiero informar UNO POR UNO los que no borre---

create trigger ej10 on producto instead of delete
as
begin
	declare @producto char(8)
	delete from producto where prod_codigo not in (select stoc_producto from deleted join STOCK on stoc_producto = prod_codigo where stoc_cantidad > 0) --lo de parentesis son los que no se pueden borrar
	declare c1 cursor for select distinct stoc_producto from deleted join STOCK on stoc_producto = prod_codigo where stoc_cantidad > 0
	open c1
	fetch next c1 into @producto
	while @@FETCH_STATUS = 0
	begin
		print('el producto' + @producto + 'no se pudo borrar porque tiene stock')
		fetch next c1 into @producto
	end
	close c1
	deallocate c1
end
go


/*
11. Cree el/los objetos de base de datos necesarios para que dado un código de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que
tengan un código mayor que su jefe directo.
*/

alter function cantEmpleados (@empleado numeric(6))
returns decimal(12,2)
as
begin
	declare @cantEmpl decimal(12,2)
	declare @empl numeric(6)
	declare empl_cursor cursor for select empl_codigo from Empleado where empl_jefe = @empleado
	open empl_cursor
	fetch next from empl_cursor into @empl
	select  @cantEmpl = 0
	while @@FETCH_STATUS = 0
		begin
			select @cantEmpl = @cantEmpl + 1 + dbo.cantEmpleados(@empl)
		fetch next from empl_cursor into @empl
		end
	close empl_cursor
	deallocate empl_cursor

	return @cantEmpl
end
go

select dbo.cantEmpleados(3) as cant_empleados

select * from empleado

select empl_jefe from empleado where empl_jefe = 3

/*12. Cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnologías. No se conoce la cantidad de niveles de composición existentes.*/

create trigger noCompuesto on Composicion after insert
as
begin 
	if((select SUM(dbo.esComponente(comp_producto, comp_componente)) from inserted) > 0) 
	begin
		ROLLBACK
		RAISERROR('El producto esta compuesto por si mismo')
	end
end
go

create function esComponente(@prod1 char(8), @prod2 char(8))
returns int
begin 
	if @prod1 = @prod2 return 1
	else 
		begin
			declare @prodAux char(8)
			declare prod_cursor cursor for select comp_componente from Componente where comp_producto = @prod1
			open prod_cursor
			fetch next from prod_cursor into @prodAux
			while @@FETCH_STATUS = 0
				begin
					if dbo.esComponente(@prod1, @prodAux) = 1 return 1
				fetch next from prod_cursor into @prodAux
				end
			close prod_cursor
			deallocate prod_cursor
		end
	return 0
end
go

/*
13. Cree el/los objetos de base de datos necesarios para implantar la siguiente regla
“Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de
sus empleados totales (directos + indirectos)”. Se sabe que en la actualidad dicha
regla se cumple y que la base de datos es accedida por n aplicaciones de
diferentes tipos y tecnologías
*/

create trigger reglaEmpleado on Empleado for update, delete
as
begin
	if (select COUNT(*) from inserted i where (select empl_salario from Empleado where empl_codigo = i.empl_jefe) < 0.20 * dbo.salarioTotalDeSusEmpleados(i.empl_jefe)) > 0
		ROLLBACK 
		RAISERROR('su jefe tiene salario mayor al 20% de sus empleados')

	if (select COUNT(*) from deleted i where (select empl_salario from Empleado where empl_codigo = i.empl_jefe) < 0.20 * dbo.salarioTotalDeSusEmpleados(i.empl_jefe)) > 0
		ROLLBACK 
		RAISERROR('su jefe tiene salario mayor al 20% de sus empleados')
end 
go


CREATE FUNCTION salarioTotalDeSusEmpleados(@codigo NUMERIC(6))
RETURNS DECIMAL(12,2)
AS
BEGIN
    RETURN (SELECT SUM(empl_salario + dbo.ej13(empl_codigo)) FROM Empleado WHERE empl_jefe = @codigo)
END
GO

/* 14. Agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes
que imprima la fecha, que cliente, que productos y a qué precio se realizó la
compra. No se deberá permitir que dicho precio sea menor a la mitad de la suma
de los componentes.*/


create trigger reglaComprarCompuesto on Item_factura instead of insert
as
begin
	declare @prod char(8), @precio decimal(12,2), @cantidad decimal(12,2), @tipo char(1), @sucursal char(4), @numero char(8), @fecha smalldatetime, @cliente char(4)
	
	declare cfact cursor for (select item_tipo, item_sucursal, item_numero, fact_fecha, fact_cliente from inserted join Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero group by item_tipo, item_sucursal, item_numero)
	open cfact 
	fetch next into @tipo, @sucursal, @numero, @fecha, @cliente
	while @@FETCH_STATUS = 0
		begin
			declare prod_cursor cursor for (select item_producto, item_precio, item_cantidad from inserted where item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero)
			open prod_cursor 
			fetch next from prod_cursor into @prod, @precio, @cantidad
			declare @nocumple int = 0
			while @@FETCH_STATUS = 0 and @nocumple = 0
				begin
					--caso que se puede insertar
					if @precio > (select isnull(SUM(prod_codigo), 0) from Producto join Composicion on prod_codigo = comp_componente and comp_componente = @prod)
						insert Item_Factura values(@tipo, @sucursal, @numero, @prod, @cantidad, @precio)
					else 
					if @precio < 0.5 * (select isnull(SUM(prod_codigo), 0) from Producto join Composicion on prod_codigo = comp_componente and comp_componente = @prod)
						begin
							print('La suma de los componentes es menor que el 50% del precio del producto ' +@prod+'para la fecha '+@fecha+'del cliente'+@cliente)
							select @nocumple = 1
						end
					else
						begin
							insert Item_Factura values(@tipo, @sucursal, @numero, @prod, @cantidad, @precio)
							print('La suma de los componentes es menor que el precio del producto ' + @prod+'para la fecha '+@fecha+'del cliente'+@cliente)
						end
					fetch next from prod_cursor into @prod, @precio
				end
			close prod_cursor
			deallocate prod_cursor
			if @nocumple = 1
				delete from Item_Factura where item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
				delete from Factura where fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero 
		end
	fetch next from cfa
	close cfact
	fetch next into @tipo, @sucursal, @numero
end

/*15. Cree el/los objetos de base de datos necesarios para que el objeto principal
reciba un producto como parametro y retorne el precio del mismo.
Se debe prever que el precio de los productos compuestos sera la sumatoria de
los componentes del mismo multiplicado por sus respectivas cantidades. No se
conocen los nivles de anidamiento posibles de los productos. Se asegura que
nunca un producto esta compuesto por si mismo a ningun nivel. El objeto
principal debe poder ser utilizado como filtro en el where de una sentencia
select.
*/

create function precioDelProducto(@producto char(8))
returns decimal(12,2)
as
begin
	declare @precio decimal(12,2)

	if(select COUNT(*) from Composicion where comp_producto = @producto) > 0 
		begin
			select @precio = dbo.precioTotalComponentes(comp_producto) from Producto 
					join Composicion on prod_codigo = comp_producto where prod_codigo = @producto
		end
	else
		select @precio = prod_precio from Producto where prod_codigo = @producto
	return @precio
end

create function precioTotalComponentes(@prod char(8))
returns decimal (12,2)
as
begin
	declare @precioTotal decimal(12,2) = 0
	declare @comp char(8), @cantidad decimal(12,2)

	declare cp cursor for (select comp_producto, comp_cantidad from Composicion where comp_producto = @prod)
	open cp
	fetch next from cp into @comp, @cantidad
	while @@FETCH_STATUS = 0 
		begin
			select @precioTotal = @precioTotal + @cantidad * dbo.precioTotalComponentes(@comp)
			fetch next from cp into @comp, @cantidad
		end
	close cp
	deallocate cp

	return @precioTotal
end

/*
16. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se descuenten del stock los articulos vendidos.
Se descontaran del deposito que mas producto poseea y se supone que el stock se almacena
tanto de productos simples como compuestos (si se acaba el stock de los
compuestos no se arman combos)
En caso que no alcance el stock de un deposito se descontara del siguiente y asi
hasta agotar los depositos posibles. En ultima instancia se dejara stock negativo
en el ultimo deposito que se desconto.
*/

create trigger descontarStock on Item_Factura after insert 
as 
begin
	-- un cursor para CADA item que se inserto
	declare @prod char(8), @cantVendida decimal(12,2)

	declare c cursor for (select item_producto, item_cantidad from inserted)
	open c
	fetch next from c into @prod, @cantVendida
	while @@FETCH_STATUS = 0 and @cantVendida > 0
		begin
			declare @depoElegido char(2), @stockActual decimal(12,2)
			select top 1 @depoElegido = stoc_deposito from STOCK where stoc_producto = @prod order by stoc_cantidad desc
			select @stockActual = stoc_cantidad from STOCK where stoc_deposito = @depoElegido
			
			if(@stockActual >= @cantVendida)
				begin
					update STOCK set stoc_cantidad = stoc_cantidad - @cantVendida
						where stoc_producto = @prod and stoc_deposito = @depoElegido
					set @cantVendida = 0
				end
			else 
				begin
					update STOCK set stoc_cantidad = 0 
						where stoc_producto = @prod and stoc_deposito = @depoElegido
					set @cantVendida = @cantVendida - @stockActual
				end
			fetch next from c into @prod, @cantVendida
		end
	close c
	deallocate c
end


---pruebas de las consultas 
select stoc_stock_maximo, stoc_cantidad, stoc_punto_reposicion, stoc_deposito from STOCK
where stoc_producto = '00000102'
group by stoc_deposito, stoc_stock_maximo, stoc_cantidad, stoc_punto_reposicion
order by stoc_stock_maximo desc

select stoc_deposito from STOCK
where stoc_producto = '00000102'
order by stoc_cantidad desc

/*
17. Sabiendo que el punto de reposicion del stock es la menor cantidad de ese objeto
que se debe almacenar en el deposito y que el stock maximo es la maxima
cantidad de ese producto en ese deposito, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio se cumpla automaticamente. No se
conoce la forma de acceso a los datos ni el procedimiento por el cual se
incrementa o descuenta stock
*/
	--NO SE SI ESTE ESTA BIEN TENGO MUCHAS DUDAS jijiji

create trigger reglaStock on Stock after insert, update
as
begin
	--cursor para cada stock que se inserte
	declare @prod char(8), @stock decimal(12,2), @depo char(2)
	declare s cursor for(select stoc_producto, stoc_cantidad, stoc_deposito from inserted)
	open s
	fetch next from s into @prod, @stock, @depo
	while @@FETCH_STATUS = 0
	begin
		declare @stockMax decimal(12,2), @stockMin decimal(12,2)
		select @stockMax = stoc_stock_maximo from STOCK where stoc_producto = @prod
		select @stockMin = stoc_punto_reposicion from STOCK where stoc_producto = @prod
		
		-- Validación 1: stock no debe superar el máximo
		if(@stock > @stockMax)
		begin
			RAISERROR('El stock que se quiere ingresar es mayor al maximo esperado')
			ROLLBACK
			RETURN
		end
		-- Validación 2: aviso si está por debajo del punto de reposición
		if(@stock < @stockMin)
		begin
			PRINT('El stock que se ingresa esta por debajo del punto de reposicion')
		end
		fetch next from s into @prod, @stock, @depo
	end

	close s 
	deallocate s
end

/*
18. Sabiendo que el limite de credito de un cliente es el monto maximo que se le
puede facturar mensualmente, cree el/los objetos de base de datos necesarios
para que dicha regla de negocio se cumpla automaticamente. No se conoce la
forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas
*/

--este no esta corregido por el profe pero creo que esta bien

create trigger reglaCreditoCliente on Factura instead of insert
as
begin
	--cursor para ver si los inserted cumplen
	declare @fact_id char(13), @facTotalAux decimal(12,2), @clieAux char(6), @fechaAux smalldatetime --la fecha para saber si es del mismo mes 
	declare c1 cursor for (select fact_tipo+fact_sucursal+fact_numero, fact_total, fact_cliente, fact_fecha from inserted)
	open c1 
	fetch next from c1 into @fact_id, @facTotalAux, @clieAux, @fechaAux
	while @@FETCH_STATUS = 0
	begin
		declare @limiteCred decimal(12,2), @totalFactDelMes decimal(12,2)
		select @limiteCred = clie_limite_credito from Cliente where clie_codigo = @clieAux
		select @totalFactDelMes = SUM(fact_total) from Factura where fact_cliente = @clieAux and MONTH(fact_fecha) = MONTH(@fechaAux)

		if(@facTotalAux <= @limiteCred - @totalFactDelMes) --si el total de la fact es menos o igual a lo que puede gastar ese mes..
		begin
			insert into Factura (fact_tipo,
								 fact_sucursal,
								 fact_numero,
								 fact_fecha, 
								 fact_vendedor,
								 fact_total,
								 fact_total_impuestos,
								 fact_cliente)
			select fact_tipo,
				   fact_sucursal,
				   fact_numero,
				   fact_fecha, 
				   fact_vendedor,
				   fact_total,
				   fact_total_impuestos,
				   fact_cliente
			from inserted
			where fact_tipo+fact_sucursal+fact_numero = @fact_id	
		end
		else
			print 'El cliente ' + @clieAux  + ' se pasó del limite'

		fetch next from c1 into @fact_id, @facTotalAux, @clieAux, @fechaAux
	end

	close c1
	deallocate c1

end

/*
19. Cree el/los objetos de base de datos necesarios para que se cumpla la siguiente
regla de negocio automáticamente “Ningún jefe puede tener menos de 5 años de
antigüedad y tampoco puede tener más del 50% del personal a su cargo
(contando directos e indirectos) a excepción del gerente general”. Se sabe que en
la actualidad la regla se cumple y existe un único gerente general.
*/

create trigger reglaEmpleados on Empleado after insert, update, delete
as
begin
	if exists (  -- si existe al menos un jefe (que NO sea el gerente general) que NO cumpla las condiciones
		select empl_codigo 
		from Empleado where empl_jefe is not null -- excluye al gerente general
		and datediff(year, empl_ingreso, getdate()) < 5
		or dbo.cantEmpleados(empl_jefe) <= 0.5 * (select COUNT(*) from Empleado) 
		)
	begin
	ROLLBACK
	print 'Ningun jefe puede tener menos de 5 anios de antiguedad y tampoco puede tener mas del 50% del personal a su cargo'
	end
end
go

--es la misma del punto 11
create function cantEmpleados (@empleado numeric(6)) --le paso el jefe
returns decimal(12,2)
as
begin
	declare @cantEmpl decimal(12,2), @empl numeric(6)
	declare empl_cursor cursor for select empl_codigo from Empleado where empl_jefe = @empleado
	open empl_cursor
	fetch next from empl_cursor into @empl
	select  @cantEmpl = 0
	while @@FETCH_STATUS = 0
		begin
			select @cantEmpl = @cantEmpl + 1 + dbo.cantEmpleados(@empl)
		fetch next from empl_cursor into @empl
		end
	close empl_cursor
	deallocate empl_cursor

	return @cantEmpl
end
go


/*
20. Crear el/los objeto/s necesarios para mantener actualizadas las comisiones del
vendedor.
El cálculo de la comisión está dado por el 5% de la venta total efectuada por ese
vendedor en ese mes, más un 3% adicional en caso de que ese vendedor haya
vendido por lo menos 50 productos distintos en el mes.
*/

create procedure actualizarComisiones(@vendedor numeric(6), @mes int, @anio int)
as
begin
	declare @ventaTotal decimal(12,2), @cantProdVendidos decimal(12,2), @comision decimal(12,2)
	select @ventaTotal = SUM(fact_total) from Factura 
						where fact_vendedor = @vendedor and YEAR(fact_fecha) = @anio and MONTH(fact_fecha) = @mes
	select @cantProdVendidos = COUNT(distinct item_producto) from Item_Factura join Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
						where fact_vendedor = @vendedor and YEAR(fact_fecha) = @anio and MONTH(fact_fecha) = @mes

	set @comision = 0.05 * @ventaTotal
	
	if(@cantProdVendidos >= 50) 
	set @comision = @comision + 0.03 * @ventaTotal

	update Empleado set empl_comision = @comision where empl_codigo = @vendedor 

end
go

/*
21. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que en una factura no puede contener productos de
diferentes familias. En caso de que esto ocurra no debe grabarse esa factura y
debe emitirse un error en pantalla.
*/

--este no se si esta bien
create trigger reglaDeProductosEnFactura on Factura instead of insert 
as
begin
	declare @fact_id char(13)
	declare c1 cursor for (select fact_tipo+fact_sucursal+fact_numero from inserted)
	open c1
	fetch next from c1 into @fact_id
	while @@FETCH_STATUS = 0
	begin
		if(select COUNT(distinct prod_familia) from Item_Factura join producto on item_producto = prod_codigo 
			where item_tipo+item_sucursal+item_numero = @fact_id) > 1
			RAISERROR('Esta factura no puede ser grabada por tener productos de la misma familia')
		else 
		--si pasa la validacion se inserta
		begin
			insert into Factura (fact_tipo,
								 fact_sucursal,
								 fact_numero,
								 fact_fecha, 
								 fact_vendedor,
								 fact_total,
								 fact_total_impuestos,
								 fact_cliente)
			select fact_tipo,
				   fact_sucursal,
				   fact_numero,
				   fact_fecha, 
				   fact_vendedor,
				   fact_total,
				   fact_total_impuestos,
				   fact_cliente
			from inserted

			where fact_tipo+fact_sucursal+fact_numero = @fact_id	
		end
		fetch next from c1 into @fact_id
	end
end

/*
22. Se requiere recategorizar los rubros de productos, de forma tal que nigun rubro
tenga más de 20 productos asignados, si un rubro tiene más de 20 productos
asignados se deberan distribuir en otros rubros que no tengan mas de 20
productos y si no entran se debra crear un nuevo rubro en la misma familia con
la descirpción “RUBRO REASIGNADO”, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio quede implementada.
*/




/*
23. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se controle que en una misma factura no puedan venderse más
de dos productos con composición. Si esto ocurre debera rechazarse la factura.
*/

--lo hizo reinosa en una clase pero no entiendo porque no compila ???

create trigger reglaComposicion on Item_factura for insert 
as
begin
	if (select COUNT(distinct item_producto) from inserted 
		join Composicion on item_producto = comp_producto) > 2
	begin
		DELETE FROM Item_Factura where item_tipo+item_sucursal+item_numero in (select item_tipo+item_sucursal+item_numero from inserted)
		DELETE FROM Factura where fact_tipo+fact_sucursal+fact_numero in (select fact_tipo+fact_sucursal+fact_numero from inserted)
		RAISERROR('Factura rechazada, no puede haber mas de dos productos con composicion')
		ROLLBACK
	end
end


/*
24. Se requiere recategorizar los encargados asignados a los depositos. Para ello
cree el o los objetos de bases de datos necesarios que lo resueva, teniendo en
cuenta que un deposito no puede tener como encargado un empleado que
pertenezca a un departamento que no sea de la misma zona que el deposito, si
esto ocurre a dicho deposito debera asignársele el empleado con menos
depositos asignados que pertenezca a un departamento de esa zona.
*/

--resuelto en clase 29 1:50:00

/*
25. Desarrolle el/los elementos de base de datos necesarios para que no se permita
que la composición de los productos sea recursiva, o sea, que si el producto A
compone al producto B, dicho producto B no pueda ser compuesto por el
producto A, hoy la regla se cumple.
*/
/*
26. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que una factura no puede contener productos que
sean componentes de otros productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla.
*/

/*
27. Se requiere reasignar los encargados de stock de los diferentes depósitos. Para
ello se solicita que realice el o los objetos de base de datos necesarios para
asignar a cada uno de los depósitos el encargado que le corresponda,
entendiendo que el encargado que le corresponde es cualquier empleado que no
es jefe y que no es vendedor, o sea, que no está asignado a ningun cliente, se
deberán ir asignando tratando de que un empleado solo tenga un deposito
asignado, en caso de no poder se irán aumentando la cantidad de depósitos
progresivamente para cada empleado.
*/
/*
28. Se requiere reasignar los vendedores a los clientes. Para ello se solicita que
realice el o los objetos de base de datos necesarios para asignar a cada uno de los
clientes el vendedor que le corresponda, entendiendo que el vendedor que le
corresponde es aquel que le vendió más facturas a ese cliente, si en particular un
cliente no tiene facturas compradas se le deberá asignar el vendedor con más
venta de la empresa, o sea, el que en monto haya vendido más.
*/
/*
29. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que una factura no puede contener productos que
sean componentes de diferentes productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla.
*/
/*
30. Agregar el/los objetos necesarios para crear una regla por la cual un cliente no
pueda comprar más de 100 unidades en el mes de ningún producto, si esto
ocurre no se deberá ingresar la operación y se deberá emitir un mensaje “Se ha
superado el límite máximo de compra de un producto”. Se sabe que esta regla se
cumple y que las facturas no pueden ser modificadas.
*/
/*
31. Desarrolle el o los objetos de base de datos necesarios, para que un jefe no pueda
tener más de 20 empleados a cargo, directa o indirectamente, si esto ocurre
debera asignarsele un jefe que cumpla esa condición, si no existe un jefe para
asignarle se le deberá colocar como jefe al gerente general que es aquel que no
tiene jefe.*/
