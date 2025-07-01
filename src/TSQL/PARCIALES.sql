--- 27-11-2024 ---

/* 2. Se requiere diseñar e implemetar los objetos necesarios para crear una regla que detecte inconsistencias en
las ventas en linea. En caso de detectar una incosistencia, deberá registrarse el detalle correspondiente en una estructura
adicional. POr el contrario, si no se encuentra ninguna incosistencia, se deberá registrar que la factura ha sido validada

Inconsistencias a considerar:
    1. Que el valor de fact_total no coincida con la suma de los precios multiplicados por la cantidades que los articulos
    2. Que se genere una factura con una fecha anterior al día actual
    3. Que se intente eliminar algun registro de una venta
*/


create table ValidacionesFactura(
	fact_id char(13),
    estado varchar(20), -- 'VALIDADA' o 'ERROR'
	motivo varchar(100)
)

create trigger trg_validar_venta on Factura after insert, delete
as
begin
--- logica para INSERT  
	if exists (select * from inserted)
	begin
		declare @fact_id char(13), @fact_total decimal(12,2), @fact_fecha smalldatetime

		declare c1 cursor for select fact_tipo+fact_sucursal+fact_numero, fact_total, fact_fecha from inserted
		open c1 
		fetch next from c1 into @fact_id, @fact_total, @fact_fecha
		while @@FETCH_STATUS = 0
		begin
			declare @sumaItems decimal(12,2)

			select @sumaItems = (select isnull(SUM(item_cantidad * item_precio), 0) from Item_Factura where item_tipo+item_sucursal+item_numero = @fact_id)

			if (@fact_total <> @sumaItems)
				insert into ValidacionesFactura values(@fact_id, 'ERROR', 'Total factura no coincide con suma de ítems')

			else if(CONVERT(date, @fact_fecha) < CONVERT(date, GETDATE()))
				insert into ValidacionesFactura values(@fact_id, 'ERROR', 'Fecha anterior al día actual')
			else
			insert into ValidacionesFactura values(@fact_id, 'VALIDADA', 'Factura validada correctamente')

		fetch next from c1 into @fact_id, @fact_total, @fact_fecha
		end

	close c1
	deallocate c1

	end
--- logica de DELETE 
	if exists(select * from deleted)
	begin
	    insert into ValidacionesFactura
		select fact_tipo+fact_sucursal+fact_numero, 'ERROR', 'Intento de eliminar una venta'
		from deleted

		raiserror('No se permite eliminar registros de facturas.', 16, 1)
		rollback
	end
end

--- 26-6-2024 ---

/* 2. Dado el contexto inflacionario se tiene que aplicar el control en el cual nunca se permita vender un producto
a un precio que no esté entre el 0%-5% del precio de venta del producto el mes anterior, ni tampoco que esté más de un 50%
el precio del mismo producto que hace 12 meses atrás. Aquellos productos nuevos, o que no estuvieron ventas en meses anteriores
no debe considerar esta regla ya que no hay precio de referencia
*/

--mi solucion pero no estoy muy segura..


create trigger trg_control_precio_inflacion on item_factura after insert 
as
begin
	declare @fact_id char(13), @item char(8), @precio decimal(12,2)
	declare c1 cursor for select item_tipo+item_sucursal+item_numero, item_producto, item_precio from inserted
	open c1
	fetch next from c1 into @fact_id, @item, @precio
	while @@FETCH_STATUS = 0
	begin
		declare @fact_fecha smalldatetime, @precioMesAnt decimal(12,2), @precio12MesesAnt decimal(12,2)
		select @fact_fecha = fact_fecha from Factura where fact_tipo+fact_sucursal+fact_numero = @fact_id

		select @precioMesAnt = avg(item_precio) from Item_Factura join Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
								where item_producto = @item and DATEDIFF(MONTH, fact_fecha, @fact_fecha) = 1
		
		select @precio12MesesAnt = avg(item_precio) from Item_Factura join Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
								where item_producto = @item and DATEDIFF(YEAR, fact_fecha, @fact_fecha) = 1
		
	-- VALIDACIONES
		if @precioMesAnt is not null
		begin
			if(@precio < 0.95 * @precioMesAnt or @precio > @precioMesAnt * 1.05)
			begin
				print('El precio de venta no está dentro del rango permitido respecto al mes anterior.')
				delete Item_Factura where item_tipo+item_sucursal+item_numero = @fact_id
				delete factura where fact_tipo+fact_sucursal+fact_numero = @fact_id	   
			end
		end

		if @precio12MesesAnt is not null
		begin
			if(@precio > 1.5 * @precio12MesesAnt)
            begin
                print('El precio de venta supera el 50% del valor de hace 12 meses.')
				delete Item_Factura where item_tipo+item_sucursal+item_numero = @fact_id
				delete factura where fact_tipo+fact_sucursal+fact_numero = @fact_id	    
			end
		end

		fetch next from c1 into @fact_id, @item, @precio
	end

	close c1
	deallocate c1
end

---resolucion de otra persona que esta bien

CREATE TRIGGER unTrigger ON Item_Factura
FOR insert
AS BEGIN
    DECLARE @PROD char(6), @FECHA SMALLDATETIME, @PRECIO decimal(12,2), 
	@SUCURSAL char(4), @NUM char(8), @TIPO char(1)
    DECLARE c1 CURSOR FOR
	select fact_numero, fact_sucursal, fact_tipo from inserted 
	join Factura on fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo

	OPEN c1
	FETCH NEXT FROM c1 INTO  @NUM, @SUCURSAL ,@TIPO

	WHILE @@FETCH_STATUS = 0
	BEGIN

	    DECLARE c2 CURSOR FOR 
		select item_producto, fact_fecha, item_precio from inserted
		join Factura on fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
		where fact_numero+fact_sucursal+fact_tipo = @NUM + @SUCURSAL + @TIPO

		OPEN c2
		FETCH NEXT FROM c2 INTO @PROD, @FECHA, @PRECIO

		WHILE @@FETCH_STATUS = 0
		BEGIN

		      IF EXISTS(select 1 from Item_Factura where item_producto = @PROD 
			  and item_numero+item_sucursal+item_tipo <> @NUM+@SUCURSAL+@TIPO)
			  BEGIN 
			        IF EXISTS( select 1 from Item_Factura 
		            join Factura on fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
		            where item_producto = @PROD and DATEDIFF(MONTH, @FECHA, fact_fecha) = 1 and @PRECIO > item_precio * 1.05)
	                BEGIN 
		               Delete Item_Factura
			           where item_numero = @NUM and item_sucursal = @SUCURSAL and item_tipo = @TIPO

			           Delete Factura
			           where fact_numero = @NUM and fact_sucursal = @SUCURSAL and fact_tipo = @TIPO

				    CLOSE c2
				    DEALLOCATE c2
			        END

			       IF EXISTS( select 1 from Item_Factura 
		           join Factura on fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
		           where item_producto = @PROD and DATEDIFF(YEAR, @FECHA, fact_fecha) = 1 and @PRECIO > item_precio * 1.5)
	               BEGIN 
		              Delete Item_Factura
			          where item_numero = @NUM and item_sucursal = @SUCURSAL and item_tipo = @TIPO

			          Delete Factura
			          where fact_numero = @NUM and fact_sucursal = @SUCURSAL and fact_tipo = @TIPO

				   CLOSE c2
				   DEALLOCATE c2
			       END
			  END

		      FETCH NEXT FROM c2 INTO @PROD, @FECHA, @PRECIO
		END
		
	    FETCH NEXT FROM c1 INTO @PROD, @FECHA, @PRECIO, @NUM, @SUCURSAL ,@TIPO   
	END

	CLOSE c1
	DEALLOCATE c1
END

--- 25-06-2024 ---

/*
Realizar el o los objetos de base de datos necesarios para que dado un codigo de producto y una fecha devuelva
la mayor cantidad de dias consecutivos a partir de esa fecha que el producto tuvo al menos la venta de una unidad en el dia, 
el sistema de ventas on line esta habilitado 24-7 por lo que se deben evaluar tidos los dias incluyendo domingos y feriados
*/

CREATE FUNCTION sellStreak(@prod char(8), @fecha SMALLDATETIME) 
RETURNS INT
AS
BEGIN
    DECLARE @fechaPivot SMALLDATETIME, @fechaAUX SMALLDATETIME
    DECLARE @cant INT = 0
    DECLARE @maxCant INT = 0

    SELECT @fechaPivot = (
        SELECT MIN(fact_fecha)
        FROM Factura 
        JOIN Item_Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
        WHERE item_producto = @prod AND fact_fecha >= @fecha
    )

    IF @fechaPivot IS NULL
        RETURN 0

    DECLARE c1 CURSOR FOR
        SELECT DISTINCT fact_fecha
        FROM Factura 
        JOIN Item_Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
        WHERE item_producto = @prod AND fact_fecha >= @fechaPivot
        ORDER BY 1

    OPEN c1
    FETCH NEXT FROM c1 INTO @fechaAUX

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @fechaAUX = DATEADD(DAY, @cant, @fechaPivot)
        BEGIN
            SET @cant = @cant + 1
        END
        ELSE
        BEGIN
            SET @fechaPivot = @fechaAUX
            SET @cant = 1
        END

        IF @cant > @maxCant
            SET @maxCant = @cant

        FETCH NEXT FROM c1 INTO @fechaAUX
    END

    CLOSE c1
    DEALLOCATE c1

    RETURN @maxCant
END


--- 20-11-2024 ---


/* 2. Se detectó un error en el proceso de registro de ventas, donde se almacenaron productos compuestos
en lugar de sus componentes individuales. Para solucionar este problema, se debe:

    1. Diseñar e implmenetar los objetos necesarios para reoganizar las ventas tal como están registradas actualmente 
    2. Desagregar los productos compuestos vendidos en sus componenetes individuales, asegurando
    que cada venta refleje correctamente los elementos que la compronen
    3. Garantizar que la base de datos quede consistente y alineada con las especificaciones requeridas para el manejo de poductos
*/

CREATE PROCEDURE reorganizarVentas
AS
BEGIN
    declare @prod char(8), @tipo char(1), @sucursal char(4), @numero char(8), @cant decimal(12,2), @precio decimal(12,2)

    declare c1 cursor for select item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio from Item_Factura where item_producto in (select comp_producto from Composicion)
    open c1
    fetch next from c1 into @tipo, @sucursal, @numero, @prod, @cant, @precio
    while @@FETCH_STATUS = 0
    BEGIN
        declare @compoAux char(8), @cantCompoAux decimal(12,2)
        declare c2 cursor for select comp_componente, comp_cantidad from Composicion where comp_producto = @prod
        open c2
        fetch next from c2 into @compoAux, @cantCompoAux
        while @@FETCH_STATUS = 0
        BEGIN
            insert into Item_Factura (
                item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio
            )
            values (
                @tipo, @sucursal, @numero, @compoAux, @cant * @cantCompoAux, @precio
            )

            fetch next from c2 into @compoAux, @cantCompoAux
        END
        close c2
        deallocate c2

        delete from Item_Factura
        where item_tipo+item_sucursal+item_numero= @tipo+@sucursal+@numero
        and item_producto = @prod

        fetch next from c1 into @tipo, @sucursal, @numero, @prod, @cant, @precio
    END

    close c1
    deallocate c1
END


-- 16-11-2024 --

/* 2. Implementar los objetos necesarios para registrar, en tiempo real, los 10 productos
más vendidos por año en una tabla especifica. Esta tabla debe contener exclusivamente la info requerida
sin incluir filas adicionales. Los más vendidos se define como aquellos productos con el mayor
numero de unidades vendidas.
*/

CREATE TABLE TopProductos(
    prod_codigo char(8),
    cant_vendida decimal(12,2),
    anio int
)

alter trigger trg_actualizar_top10 on Item_Factura after insert
as
begin
    declare @fact_id char(13), @fecha smalldatetime, @cant decimal(12,2), @prod char(8)
        declare c1 cursor for select item_tipo+item_sucursal+item_numero, fact_fecha, item_cantidad, item_producto from inserted
         join Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
    
    open c1
    fetch next from c1 into @fact_id, @fecha, @cant, @prod
    
    while @@FETCH_STATUS = 0
    begin
        declare @anio int 
        select anio = year(@fecha)

        if exists(select prod_codigo from TopProductos where anio = @anio and prod_codigo = @prod)
        begin
            update TopProductos
            set cant_vendida = cant_vendida + @cant
            where anio = @anio and prod_codigo = @prod
        end 
        else   
        begin
            if(select count(*) from TopProductos where anio = @anio) <= 10
            begin 
                insert into TopProductos (anio, prod_codigo, cantidad_vendida)
                values (@anio, @prod, @cant)
            end 
            else 
            begin --si hay mas de 10 productos borrar el que menos cantidad tenga
                delete from TopProductos where anio = @anio
                    and cantidad_vendida = (select min(cantidad_vendida) from TopProductos where anio = @anio) 
                    and prod_codigo not in (select top 10 prod_codigo from TopProductos where anio = @anio order by cantidad_vendida desc)
            end 
        end 

        fetch next from c1 into @fact_id, @fecha, @cant, @prod
    end

    close c1 
    deallocate c1
end 

-- 22-11-2022 --

/*
1. Implementar una regla de negocio en linea donde se valide que nuncа
un producto compuesto pueda estar compuesto por componentes de rubros distintos a el.
*/

CREATE TRIGGER compuestosRubros ON Composicion AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED i
        JOIN Producto compuesto ON i.comp_producto = compuesto.prod_codigo
        JOIN Producto componente ON i.comp_componente = componente.prod_codigo
        WHERE compuesto.prod_rubro <> componente.prod_rubro
    )
    BEGIN
        RAISERROR('No se puede tener un producto compuesto por componentes con rubros distintos a el', 16, 1)
        ROLLBACK TRANSACTION
    END
END


-- 13-11-2024 --

/*
Implementar un sistema de auditoria para registrar cada operacion realizada en la tabla 
cliente. El sistema debera almacenar, como minimo, los valores(campos afectados), el tipo 
de operacion a realizar, y la fecha y hora de ejecucion. SOlo se permitiran operaciones individuales
(no masivas) sobre los registros, pero el intento de realizar operaciones masivas deberá ser registrado
en el sistema de auditoria
*/

CREATE TABLE AUDITORIA(
    audi_operacion char(100),
    audi_codigo char(6),
    audi_razon_social char(10),
    audi_telefono char(100),
    audi_domicilio char(100),
    audi_limite_credito decimal(12, 2),
    audi_vendedor numeric(6)
)

CREATE TRIGGER auditoria1 ON Cliente AFTER INSERT
AS
BEGIN 
    
    IF((SELECT COUNT(*) FROM Cliente) > 1)
    BEGIN 
        print 'Se intentó realizar una operacion masiva'
        INSERT INTO AUDITORIA(audi_operacion) VALUES('INSERCION MASIVA')
    END
    ELSE
    BEGIN
        INSERT INTO AUDITORIA(
            audi_operacion,
            audi_codigo,
            audi_razon_social,
            audi_telefono, 
            audi_domicilio,
            audi_limite_credito, 
            audi_vendedor 
        )
        SELECT 'AFTER', clie_codigo, clie_razon_social, clie_telefono, clie_domicilio, clie_limite_credito, clie_vendedor
        FROM INSERTED 

    END
END 

-- 01-07-2023 --

/*2. la Actualmente el campo fact_vendedor representa al empleado que vendió
la factura. Implementar el/los objetos necesarios para respetar
integridad referenciales de dicho campo suponiendo que no existe una
foreign key entre ambos.

NOTA: No se puede usar una foreign key para el ejercicio, deberá buscar
otro método */

create trigger integridadVendedor on Factura after insert, update
as
begin
    if exists (
        select fact_vendedor
        from inserted i
        where not exists (
            select empl_codigo
            from Empleado
            where empl_codigo = i.fact_vendedor
        )
    )
    begin
        rollback
        raiserror('El vendedor asignado no existe en la tabla Empleado.', 16, 1)
    end
end
go
