import { Table, Column, Model, DataType } from 'sequelize-typescript'

@Table
class Score extends Model {
    @Column({ type: DataType.STRING })
    username!: string

    @Column({ type: DataType.INTEGER })
    score!: number
}

export default Score;
