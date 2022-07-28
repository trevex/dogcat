import { Controller, useGameContext } from "./GameProvider";


type GameScoreboardProps = {};

const GameScoreboard = ({ }: GameScoreboardProps) => {
    return (
        <div className="absolute inset-0 flex justify-center items-center z-10">
            <p className="text-2xl font-bold">This will be the scoreboard</p>
        </div>
    );
};

export default GameScoreboard;
