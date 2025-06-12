
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
/*
8. Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados 

item factura que-> - que tengan composición
				   - cuales el precio de facturación sea diferente al precio del cálculo de los precios unitarios por
cantidad de sus componentes, se aclara que un producto que compone a otro,
también puede estar compuesto por otros y así sucesivamente, la tabla se debe
crear y está formada por las siguientes columnas:
*/

create procedure completarTabla
as
begin 
	insert into Diferencias 
	     (prod_codigo,
         prod_detalle,
         cantidad_componentes,
         precio_compuesto,
         precio_facturado)

	select
	 prod_codigo,
	 prod_detalle,
	 dbo.cantidadCompuestosRecursivo(prod_codigo),
	 dbo.precioGenerado(prod_codigo),
	 (select top 1 item_precio from item_factura where item_producto = prod_codigo)
	
	from producto p
	join item_factura on p.prod_codigo = item_producto 
	where p.prod_codigo in (select comp_componente from Composicion) and
	dbo.precioGenerado(p.prod_codigo) <> item_precio

end
go


create function cantidadCompuestosRecursivo (@producto char(8))
returns decimal(12,2)
as
begin
	declare @cantidad decimal(12,2)
	select @cantidad = isnull(sum(1 + dbo.cantidadCompuestosRecursivo(comp_componente)), 0) from Composicion where comp_producto = @producto

	return @cantidad
end
go


create function precioGenerado(@producto char(8))
returns decimal(12,2)
as 
begin
	declare @precio decimal(12,2), @comp char(8), @cant decimal(12,2)
	if(select count(comp_componente) from composicion where comp_producto = @producto) = 0
	select @precio = prod_precio from Producto where prod_codigo = @producto
	else
		begin
			declare comp_cursor cursor for
			select comp_componente from Composicion join Producto on prod_codigo = comp_producto where comp_producto = @producto
			open empl_cursor
			fetch next from comp_cursor into @comp, @cant
			while @@FETCH_STATUS = 0
				begin
					select @precio = @precio + @cant * dbo.precioGenerado(@comp)
				fetch next from comp_cursor into @comp, @cant
			end
			close comp_cursor
			deallocate comp_cursor
		end
	return @precio
end
go


select * from Item_Factura

select item_precio from item_factura where item_producto = 00001415


/*
9. Crear el/los objetos de base de datos que ante alguna modificación de un ítem de
factura de un artículo con composición realice el movimiento de sus
correspondientes componentes.
*/










/* 10. Crear el/los objetos de base de datos que ante el intento de borrar un artículo
verifique que no exista stock y si es así lo borre en caso contrario que emita un
mensaje de error.
*/













	-- == CLASE PREENCIAL ==
/*
11. Cree el/los objetos de base de datos necesarios para que dado un código de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que
tengan un código mayor que su jefe directo.
*/














/*12. Cree el/los objetos de base de datos necesarios para que nunca un producto
p
ueda ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnologías. No se conoce la cantidad de niveles de composición existentes.*/











/*
13. Cree el/los objetos de base de datos necesarios para implantar la siguiente regla
“Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de
sus empleados totales (directos + indirectos)”. Se sabe que en la actualidad dicha
regla se cumple y que la base de datos es accedida por n aplicaciones de
diferentes tipos y tecnologías
*/
















/* 14. Agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes
que imprima la fecha, que cliente, que productos y a qué precio se realizó la
compra. No se deberá permitir que dicho precio sea menor a la mitad de la suma
de los componentes.*/













/*15. Cree el/los objetos de base de datos necesarios para que el objeto principal
reciba un producto como parametro y retorne el precio del mismo.
Se debe prever que el precio de los productos compuestos sera la sumatoria de
los componentes del mismo multiplicado por sus respectivas cantidades. No se
conocen los nivles de anidamiento posibles de los productos. Se asegura que
nunca un producto esta compuesto por si mismo a ningun nivel. El objeto
principal debe poder ser utilizado como filtro en el where de una sentencia
select.
*/








/*
16. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se descuenten del stock los articulos vendidos. Se descontaran
del deposito que mas producto poseea y se supone que el stock se almacena
tanto de productos simples como compuestos (si se acaba el stock de los
compuestos no se arman combos)
En caso que no alcance el stock de un deposito se descontara del siguiente y asi
hasta agotar los depositos posibles. En ultima instancia se dejara stock negativo
en el ultimo deposito que se desconto.
*/








/*
17. Sabiendo que el punto de reposicion del stock es la menor cantidad de ese objeto
que se debe almacenar en el deposito y que el stock maximo es la maxima
cantidad de ese producto en ese deposito, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio se cumpla automaticamente. No se
conoce la forma de acceso a los datos ni el procedimiento por el cual se
incrementa o descuenta stock
*/







/*
18. Sabiendo que el limite de credito de un cliente es el monto maximo que se le
puede facturar mensualmente, cree el/los objetos de base de datos necesarios
para que dicha regla de negocio se cumpla automaticamente. No se conoce la
forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas
*/








/*
19. Cree el/los objetos de base de datos necesarios para que se cumpla la siguiente
regla de negocio automáticamente “Ningún jefe puede tener menos de 5 años de
antigüedad y tampoco puede tener más del 50% del personal a su cargo
(contando directos e indirectos) a excepción del gerente general”. Se sabe que en
la actualidad la regla se cumple y existe un único gerente general.
*/






/*
20. Crear el/los objeto/s necesarios para mantener actualizadas las comisiones del
vendedor.
El cálculo de la comisión está dado por el 5% de la venta total efectuada por ese
vendedor en ese mes, más un 3% adicional en caso de que ese vendedor haya
vendido por lo menos 50 productos distintos en el mes.
*/




/*
21. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que en una factura no puede contener productos de
diferentes familias. En caso de que esto ocurra no debe grabarse esa factura y
debe emitirse un error en pantalla.
*/



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
/*
24. Se requiere recategorizar los encargados asignados a los depositos. Para ello
cree el o los objetos de bases de datos necesarios que lo resueva, teniendo en
cuenta que un deposito no puede tener como encargado un empleado que
pertenezca a un departamento que no sea de la misma zona que el deposito, si
esto ocurre a dicho deposito debera asignársele el empleado con menos
depositos asignados que pertenezca a un departamento de esa zona.
*/
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
