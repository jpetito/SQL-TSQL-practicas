/*Realizar una consulta SQL que retorne para todas las zonas que tengan
3 (tres) o más depósitos.
    1) Detalle Zona
    2) Cantidad de Depósitos x Zona
    3) Cantidad de Productos distintos compuestos en sus depósitos
    4) Producto mas vendido en el año 2012 que tenga stock en al menos
    uno de sus depósitos.
    5) Mejor encargado perteneciente a esa zona (El que mas vendió en la
        historia).
El resultado deberá ser ordenado por monto total vendido del encargado
descendiente.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones
definidas por el usuario para este punto.
*/

 select zona_detalle,
		COUNT(distinct depo_codigo) as cant_depos,
		(select COUNT(distinct s.stoc_producto) from STOCK s join deposito d on d.depo_codigo = s.stoc_deposito where s.stoc_deposito = depo_codigo 
		and d.depo_zona = zona_codigo and s.stoc_producto in (select comp_componente from Composicion)) as cant_comps,
		(select top 1 item_producto from Item_Factura join factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
				join STOCK s1 on s1.stoc_producto = item_producto 
				join DEPOSITO d1 on d1.depo_codigo = s1.stoc_deposito 
				where year(fact_fecha) = 2012 and d1.depo_zona = zona_codigo 
				group by item_producto 
				order by SUM(item_cantidad) desc) as prod_mas_vendido,
		(select top 1 fact_vendedor from Factura join Item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
				join Producto on item_producto = prod_codigo join STOCK s2 on stoc_producto = item_producto 
				join deposito d2 on d2.depo_codigo = s2.stoc_deposito
				where s2.stoc_deposito = depo_codigo and d2.depo_zona = zona_codigo
				group by fact_vendedor
				order by SUM(fact_total) desc) as mejor_encargado
 from Zona join DEPOSITO on zona_codigo = depo_zona
 join STOCK on stoc_deposito = depo_codigo
 group by zona_detalle, zona_codigo
 having COUNT(distinct depo_codigo) >= 3
 order by 5


