> [!IMPORTANT]
> ## Purpose
><!-- Por qué es necesario este PR, que soluciona, mejora o que nuevo feature a nivel de negocio implementa -->
>
>

> [!IMPORTANT]
> ## Brief description
><!-- Explicar brevemente como es el flujo para realizar lo que necesita -->
>
>

> [!NOTE]
> ## Reference links:
><!-- cambiar el codigo del ticket de jira -->
>
> [Jira](https://link.a.jira)

> [!TIP]
> ## How to test?
><!-- cURLs, flujos de prueba, donde se ejecutaron las mismas (scope) -->
>
>
>### Evidence
>- [ ] Attach screenshots.
>### Additional checks
>- [ ] Add milestone.
>- [ ] Updated docs.
>
>### 📝 Json's
><!-- Agrega jsons del cambio antes y después - solo del componente modificado -->
>
>

> [!CAUTION]
> ##  How to merge
> |head branch. |base branch. |merge operation. |
> |-------------|-------------|-----------------|
> | feature/.*  | develop     | squash & merge  |
> | release/.*  | master      | merge           |
> | backport/.* | develop     | merge           |
> | backport/.* | release/.*  | merge           |
> | fix/.*      | release/.*  | squash & merge  |
> | hotfix/.*   | master      | squash & merge  |
> | feature/.*  | release/.*  | squash & merge  |


> [!Warning]
> ##  Release Process
><table style="width:100%">
  <tr> 
    <th> Martes 12 hs </th>
    <th> Miércoles hasta 12 hs </th>
    <th> Miércoles 14  hs </th>
    <th> Jueves 11 hs </th>
  </tr>
  <tr>
    <td> Cierre release con los PRs que estan en develop </td> 
    <td> Despliegue de la release en scope de test para pruebas </td>
    <td> Despliegue de la release en producción de modo candidate. </td>
    <td> Merge de la release y despliegue de la versión estable  </td>
  </tr>
</table>